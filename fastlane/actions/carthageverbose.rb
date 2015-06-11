module Fastlane
  module Actions
    class CarthageverboseAction < Action
      def self.run(params)
        cmd = ['carthage bootstrap']

        cmd << '--verbose' if params[:verbose]

        Actions.sh(cmd.join(' '))
      end

      def self.description
        "Runs `carthage bootstrap` for your project, with optional verbose output"
      end

      def self.author
        "andreaskumlehn"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :verbose,
                                       env_name: "FL_CARTHAGE_VERBOSE",
                                       description: "Enable verbose output of bootstrap? (true/false)",
                                       optional: true,
                                       default_value: false,
                                       is_string: false)
          ]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end