# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'Stream Mirror' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  pod 'AWSS3'
  pod 'Google-Mobile-Ads-SDK'
  pod 'google-cast-sdk'
  pod 'ConnectSDK/Core'
  pod 'SVProgressHUD'
  pod 'ShimmerSwift'
  pod 'Toast-Swift'
  pod 'lottie-ios'
  pod 'SDWebImage'
  
  post_install do |installer|
     installer.generated_projects.each do |project|
       project.targets.each do |target|
         target.build_configurations.each do |config|
           config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.1'
         end
       end
     end
   end
  # Pods for Stream Mirror

end
