require "English"
require "fileutils"

require_relative "css_scope"

module Postnhost
  class CssBuild
    POLL_INTERVAL = 0.1

    class << self
      def run(command:, unscoped_path:, output_path:, watch: false)
        FileUtils.rm_f(unscoped_path)

        if watch
          watch(command:, unscoped_path:, output_path:)
        else
          system(*command, exception: true)
          CssScope.scope_file(unscoped_path, output_path)
        end
      ensure
        FileUtils.rm_f(unscoped_path)
      end

      private

      def watch(command:, unscoped_path:, output_path:)
        process_id = Process.spawn(*command)
        applied_signature = nil
        pending_signature = nil

        loop do
          process_status = Process.waitpid(process_id, Process::WNOHANG)
          signature = file_signature(unscoped_path)

          if signature && signature == pending_signature && signature != applied_signature
            CssScope.scope_file(unscoped_path, output_path)
            applied_signature = signature
          end

          pending_signature = signature
          break if process_status

          sleep POLL_INTERVAL
        end

        raise "Tailwind CSS watcher exited unsuccessfully" unless $CHILD_STATUS.success?
      ensure
        terminate(process_id)
      end

      def file_signature(path)
        return unless File.exist?(path)

        stat = File.stat(path)
        [stat.mtime.to_f, stat.size]
      end

      def terminate(process_id)
        return unless process_id

        Process.kill("TERM", process_id)
        Process.wait(process_id)
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      end
    end
  end
end
