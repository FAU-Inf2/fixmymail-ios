module Fastlane
  module Actions
    class CocoapodsAction < Action
      def self.run(params)

        cmd = ['pod install']
        cmd << '--verbose' if params[:verbose]

        Actions.sh(cmd.join(' '))
      end

      def self.description
        "Runs `pod install` for the project"
      end
      
      def self.author
        "andreaskumlehn"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :verbose,
                                       env_name: "FL_COCOAPODS_VERBOSE",
                                       description: "Show more debugging information",
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
#  vim: set et sw=2 ts=2 :