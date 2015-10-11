# Uncomment this line to define a global platform for your project
platform :ios, '9.0'
use_frameworks!

post_install do |installer|
	installer.pods_project.targets.each do |target|
		target.build_configurations.each do |config|
			config.build_settings['ENABLE_BITCODE'] = 'NO'
		end
	end
end

target 'SMile' do
	pod 'mailcore2-ios'
	#pod 'mailcore2-ios', :git => 'https://github.com/FAU-Inf2/mailcore2.git', :branch => :bitcode
	#pod 'OpenSSL-Universal', '=1.0.1.h'
	pod 'Locksmith', :git => 'https://github.com/matthewpalmer/Locksmith.git', :branch => :master
	pod 'SwiftyJSON', :git => 'https://github.com/SwiftyJSON/SwiftyJSON.git'
	pod 'SMilePGP', :git => 'https://github.com/FAU-Inf2/SMilePGP.git', :branch => :master

end

target 'SMileTests' do

end

