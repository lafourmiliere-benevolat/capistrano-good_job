module Capistrano
  class GoodJob < Capistrano::Plugin
    def set_defaults
      set_if_empty :good_job_role, "db"
      set_if_empty :good_job_access_log, -> { File.join(shared_path, "log", "good_job.log") }
      set_if_empty :good_job_error_log, -> { File.join(shared_path, "log", "good_job.log") }
      set_if_empty :good_job_service_unit_name, -> { "#{fetch(:application)}_good_job_#{fetch(:stage)}" }
      set_if_empty :good_job_systemd_conf_dir, -> { fetch_systemd_unit_path }
    end

    def define_tasks
      eval_rakefile File.expand_path("../tasks/good_job.rake", __FILE__)
    end

    def register_hooks
      after "deploy:finished", "good_job:restart"
    end

    def execute_systemd(*args)
      command = ["/bin/systemctl", "--user"] + args
      backend.execute(*command)
    end

    def fetch_systemd_unit_path
      if fetch(:good_job_systemctl_user) == :system
        "/etc/systemd/system/"
      else
        home_dir = backend.capture :pwd
        File.join(home_dir, ".config", "systemd", "user")
      end
    end
  end
end
