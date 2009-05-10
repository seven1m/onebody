require "md5"
require "thread"
require "servicestate"

# This class will watch a directory or a set of directories and alert you of
# new files, modified files, deleted files. You can optionally only be alerted
# when a files md5 hash has been changed so you only are alerted to real changes.
# this of course means slower performance and higher cpu/io usage.
class FileSystemWatcher
  include ServiceState

  CREATED = 0
  MODIFIED = 1
  DELETED = 2

  # the time to wait before checking the directories again
  attr_accessor :sleepTime, :priority

  # you can optionally use the file contents md5 to detect if a file has changed
  attr_accessor :useMD5

  def initialize(dir=nil, expression="**/*")
    @sleepTime = 5
    @useMD5 = false
    @priority = 0
    @stopWhen = nil

    @directories = Array.new()
    @files = Array.new()

    @foundFiles = nil
    @firstLoad = true
    @watchThread = nil
    
    initializeState()

    if dir then
      addDirectory(dir, expression)
    end
  end

  # add a directory to be watched
  # @param dir the directory to watch
  # @param expression the glob pattern to search under the watched directory
  def addDirectory(dir, expression="**/*")
    if FileTest.exists?(dir) && FileTest.readable?(dir) then
      @directories << FSWatcher::Directory.new(dir, expression)
    else
      raise FSWatcher::InvalidDirectoryError, "Dir '#{dir}' either doesnt exist or isnt readable"
    end
  end

  def removeDirectory(dir)
    @directories.delete(dir)
  end

  # add a specific file to the watch list
  # @param file the file to watch
  def addFile(file)
    if FileTest.exists?(file) && FileTest.readable?(file) then
      @files << file
    else
      raise FSWatcher::InvalidFileError, "File '#{file}' either doesnt exist or isnt readable"
    end
  end

  def removeFile(file)
    @files.delete(file)
  end

  # start watching the specified files/directories
  def start(&block)
    if isStarted? then
      raise RuntimeError, "already started"
    end

    setState(STARTED)

    @firstLoad = true
    @foundFiles = Hash.new()

    # we watch in a new thread
    @watchThread = Thread.new {
      # we will be stopped if someone calls stop or if someone set a stopWhen that becomes true
      while !isStopped? do
	if (!@directories.empty?) or (!@files.empty?) then	
	  # this will hold the list of the files we looked at this iteration
	  # allows us to not look at the same file again and also to compare
	  # with the foundFile list to see if something was deleted
	  alreadyExamined = Hash.new()
	  
	  # check the files in each watched directory
	  if not @directories.empty? then
	    @directories.each { |dirObj|
	      examineFileList(dirObj.getFiles(), alreadyExamined, &block)
	    }
	  end
	  
	  # now examine any files the user wants to specifically watch
	  examineFileList(@files, alreadyExamined, &block) if not @files.empty?
	  
	  # see if we have to delete files from our found list
	  if not @firstLoad then
	    if not @foundFiles.empty? then
	      # now diff the found files and the examined files to see if
	      # something has been deleted
	      allFoundFiles = @foundFiles.keys()
	      allExaminedFiles = alreadyExamined.keys()
	      intersection = allFoundFiles - allExaminedFiles
	      intersection.each { |fileName|
		# callback
		block.call(DELETED, fileName)
		# remove deleted file from the foundFiles list
		@foundFiles.delete(fileName)
	      }	  
	    end
	  else
	    @firstLoad = false
	  end
	end
	
	# go to sleep
	sleep(@sleepTime)
      end
    }
    
    # set the watch thread priority
    @watchThread.priority = @priority

  end

  # kill the filewatcher thread
  def stop()
    setState(STOPPED)
    @watchThread.wakeup()
  end

  # wait for the filewatcher to finish
  def join()
    @watchThread.join() if @watchThread
  end


  private

  # loops over the file list check for new or modified files
  def examineFileList(fileList, alreadyExamined, &block)
    fileList.each { |fileName|
      # expand the file name to the fully qual path
      fullFileName = File.expand_path(fileName)

      # dont examine the same file 2 times
      if not alreadyExamined.has_key?(fullFileName) then
	# we cant do much if the file isnt readable anyway
	if File.readable?(fullFileName) then
	  # set that we have seen this file
	  alreadyExamined[fullFileName] = true
	  
	  # get the file info
	  modTime, size = File.mtime(fullFileName), File.size(fullFileName)
	  
	  # on the first iteration just load all of the files into the foundList
	  if @firstLoad then
	    @foundFiles[fullFileName] = FSWatcher::FoundFile.new(fullFileName, modTime, size, false, @useMD5)
	  else
	    # see if we have found this file already
	    foundFile = @foundFiles[fullFileName]

	    if foundFile then
	      
	      # if a file is marked as new, we still need to make sure it isnt still
	      # being written to. we do this by checking the file sizes.
	      if foundFile.isNew? then
		
		# if the file size is the same then it is probably done being written to
		# unless the writer is really slow
		if size == foundFile.size then		  

		  # callback
		  block.call(CREATED, fullFileName)
		  
		  # mark this file as a changed file now
		  foundFile.updateModTime(modTime)
		  
		  # generate the md5 for the file since we know it is done
		  # being written to
		  foundFile.genMD5() if @useMD5
		  
		else
		  
		  # just update the size so we can check again at the next iteration
		  foundFile.updateSize(size)
		  
		end
		
	      elsif modTime > foundFile.modTime then

		# if the mod times are different on files we already have
		# found this is an update		
		willYield = true
		
		# if we are using md5's then compare them
		if @useMD5 then
		  filesMD5 = FSWatcher.genFileMD5(fullFileName)
		  if filesMD5 && foundFile.md5 then
		    if filesMD5.to_s == foundFile.md5.to_s then
		      willYield = false
		    end
		  end
		  
		  # if we are yielding then the md5s are dif so
		  # update the cached md5 value
		  foundFile.setMD5(filesMD5) if willYield

		end
		
		block.call(MODIFIED, fullFileName) if willYield		
		foundFile.updateModTime(modTime)

	      end

	    else	      

	      # this is a new file for our list. dont update the md5 here since
	      # the file might not yet be done being written to
	      @foundFiles[fullFileName] = FSWatcher::FoundFile.new(fullFileName, modTime, size)
	      
	    end
	  end
	end
      end
    }
  end
end

# Util classes for the FileSystemWatcher
module FSWatcher
  # The directory to watch
  class Directory
    attr_reader :dir, :expression

    def initialize(dir, expression)
      @dir, @expression = dir, expression
      @dir.chop! if @dir =~ %r{/$}
    end

    def getFiles()
      return Dir[@dir + "/" + @expression]
    end
  end

  # A FoundFile entry for the FileSystemWatcher
  class FoundFile
    attr_reader :status, :fileName, :modTime, :size, :md5

    def initialize(fileName, modTime, size, isNewFile=true, useMD5=false)
      @fileName, @modTime, @size, @isNewFile  = fileName, modTime, size, isNewFile      
      @md5 = nil
      if useMD5 then
	genMD5()
      end
    end

    def updateModTime(modTime)
      @modTime = modTime
      @isNewFile = false
    end

    def updateSize(size)
      @size = size
    end

    def isNew?
      return @isNewFile
    end

    def setMD5(newMD5)
      @md5 = newMD5
    end

    # generate my files md5 value
    def genMD5()
      @md5 = FSWatcher.genFileMD5(@fileName)
    end
  end

  # utility function for generating md5s from a files contents
  def FSWatcher.genFileMD5(fileName)
    if FileTest.file?(fileName) then      
      f = File.open(fileName)
      contents = f.read()
      f.close()
      return MD5.new(contents) if contents
    end
    return nil
  end

  # if the directory you want to watch doesnt exist or isnt readable this is thrown
  class InvalidDirectoryError < StandardError; end

  # if the file you want to watch doesnt exist or isnt readable this is thrown
  class InvalidFileError < StandardError; end
end

#--- main program ----
if __FILE__ == $0
  watcher = FileSystemWatcher.new()
  watcher.addDirectory("/cygdrive/c/Inetpub/ftproot/", "*.xml")
  watcher.sleepTime = 3
  watcher.useMD5 = true

  test = false
  watcher.stopWhen {
    test == true
  }

  watcher.start() { |status,file|
    if status == FileSystemWatcher::CREATED then
      puts "created: #{file}"
    elsif status == FileSystemWatcher::MODIFIED then
      puts "modified: #{file}"
    elsif status == FileSystemWatcher::DELETED then
      puts "deleted: #{file}"
    end
  }

  sleep(10)
  test = true
  watcher.join()
end
