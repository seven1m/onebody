# these are events that fired before all the js was loaded, now we can catch up...
for e in event_queue
  $(e.target).trigger(e.type)
event_queue.length = 0
