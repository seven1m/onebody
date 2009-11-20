# ---------------------------------------------------------------------------
# This is a recipe definition file for Capistrano. The tasks are documented
# below.
# ---------------------------------------------------------------------------
# This file is distributed under the terms of the MIT license by 37signals,
# LLC, and is copyright (c) 2008 by the same. See the LICENSE file distributed
# with this file for the complete text of the license.
# ---------------------------------------------------------------------------
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

namespace :fast_remote_cache do

  desc <<-DESC
    Perform any setup required by fast_remote_cache. This is called
    automatically after deploy:setup, but may be invoked manually to configure
    a new machine. It is also necessary to invoke when you are switching to the
    fast_remote_cache strategy for the first time.
  DESC
  task :setup, :except => { :no_release => true } do
    if deploy_via == :fast_remote_cache
      strategy.setup!
    else
      logger.important "you're including the fast_remote_cache strategy, but not using it!"
    end
  end

  desc <<-DESC
    Updates the remote cache. This is handy for either priming a new box so
    the cache is all set for the first deploy, or for preparing for a large
    deploy by making sure the cache is updated before the deploy goes through.
    Either way, this will happen automatically as part of a deploy; this task
    is purely convenience for giving admins more control over the deployment.
  DESC
  task :prepare, :except => { :no_release => true } do
    if deploy_via == :fast_remote_cache
      strategy.prepare!
    else
      logger.important "#{current_task.fully_qualified_name} only works with the fast_remote_cache strategy"
    end
  end
end

after "deploy:setup", "fast_remote_cache:setup"
