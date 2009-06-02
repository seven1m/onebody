require 'thread'

# The Runnable module is a generic mixin for including state and
# status information in a class
module ServiceState
  # state constants
  NOT_STARTED = 0
  STARTED = 1
  STOPPED = 2
  CONFIGURED = 3
  
  attr_reader :startTime, :endTime
  
  # Initialize the state information
  def initializeState()
    @configured = false
    @startTime = 0
    @stopTime = 0
    
    @stateMutex = Mutex.new()
    @stopWhen = nil
    setState(NOT_STARTED)
  end
  
  # Set the callback for when someone calls setState. You
  # will be passed the state CONSTANT being set
  def onStateChange(&callbackBlock)
    @stateCallback = callbackBlock
  end
  
  # All methods, inside this class or not, should use this
  # method to change the state of the JobRunner
  # @param newState The new state value
  def setState(newState)
    @stateMutex.synchronize {
      if newState == CONFIGURED then
	@configured = true
      else
	@state = newState
	if isStarted? then
	  @startTime = Time.now()
	elsif isStopped?
	  @stopTime = Time.now()
	end
      end
    }
    
    if defined?(@stateCallback) then
      @stateCallback.call(newState)
    end
  end
  
  def isConfigured?
    return @configured
  end

  def isStarted?
    return @state == STARTED
  end

  def isStopped?
    if @state == STOPPED then
      return true
    elsif @stopWhen && @stopWhen.call() then
      setState(STOPPED)
      return true
    else
      return false
    end
  end   

  def stopWhen(&block)
    @stopWhen = block
  end
end
