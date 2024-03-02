# frozen_string_literal: true

module Capistrano
  module GoodJobCommon
    def good_job_user(role = nil)
      if role.nil?
        fetch(:good_job_user)
      else
        properties = role.properties
        properties.fetch(:good_job_user) || # local property for good job only
          fetch(:good_job_user) ||
          properties.fetch(:run_as) || # global property across multiple capistrano gems
          role.user
      end
    end
  end

  class GoodJob < Capistrano::Plugin
    def set_defaults
      set_if_empty :good_job_role, "db"
      set_if_empty :good_job_access_log, -> { File.join(shared_path, "log", "good_job.log") }
      set_if_empty :good_job_error_log, -> { File.join(shared_path, "log", "good_job.log") }
      set_if_empty :good_job_env, -> { fetch(:rack_env, fetch(:rails_env, fetch(:stage))) }
      set_if_empty :good_job_service_unit_type, -> { "notify" }
      set_if_empty :good_job_service_unit_name, -> { "#{fetch(:application)}_good_job_#{fetch(:stage)}" }
      set_if_empty :good_job_systemctl_bin, -> { fetch(:systemctl_bin, "/bin/systemctl") }
      set_if_empty :good_job_systemctl_user, -> { fetch(:systemctl_user, :user) }
      set_if_empty :good_job_systemd_conf_dir, -> { fetch_systemd_unit_path }

      set :good_job_service_unit_env_vars, {}
    end

    def define_tasks
      eval_rakefile File.expand_path("tasks/good_job.rake", __dir__)
    end

    def register_hooks
      after "deploy:finished", "good_job:restart"
    end

    def systemd_command(*args)
      command = [fetch(:good_job_systemctl_bin)]

      command << "--user" unless fetch(:good_job_systemctl_user) == :system

      command + args
    end

    def sudo_if_needed(*command)
      if fetch(:good_job_systemctl_user) == :system
        backend.sudo command.map(&:to_s).join(" ")
      else
        backend.execute(*command)
      end
    end

    def execute_systemd(*args)
      sudo_if_needed(*systemd_command(*args))
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
