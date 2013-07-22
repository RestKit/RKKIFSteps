Pod::Spec.new do |s|
  s.name         = "RKKIFSteps"
  s.version      = "0.20.3"
  s.summary      = "A set of steps for use in testing RestKit applications with the KIF (Keep It Functional) integration testing library."
  s.homepage     = "https://github.com/RestKit/RKKIFSteps"

  s.license      = { :type => 'Apache', :file => 'LICENSE'}

  s.author       = { "Blake Watters" => "blakewatters@gmail.com" }

  s.platform     = :ios, '5.0'
  s.requires_arc = true
  
  s.source       = { :git => "https://github.com/RestKit/RKKIFSteps.git", :branch => 'master' }
  s.source_files = 'Code/*.{h,m}'
  
  # NOTE: The RestKit dependency is not specified within the Podspec because this pod is designed to be exclusively linked into the unit testing bundle target. Directly specifying RestKit causes the compilation of a secondary copy of the library.
  #s.dependency 'RestKit/Testing', '~> 0.20.0'
  s.dependency 'KIF', '>= 0.0.1'
  
  # Add Core Data to the PCH (This should be optional, but there's no good way to configure this with CocoaPods at the moment)
  # Add Core Data to the PCH if RestKit/CoreData has been imported
  s.prefix_header_contents = <<-EOS
#import <Availability.h>

#define _AFNETWORKING_PIN_SSL_CERTIFICATES_

#if __IPHONE_OS_VERSION_MIN_REQUIRED
  #import <SystemConfiguration/SystemConfiguration.h>
  #import <MobileCoreServices/MobileCoreServices.h>
  #import <Security/Security.h>
#else
  #import <SystemConfiguration/SystemConfiguration.h>
  #import <CoreServices/CoreServices.h>
  #import <Security/Security.h>
#endif

#ifdef COCOAPODS_POD_AVAILABLE_RestKit_CoreData
    #import <CoreData/CoreData.h>
#endif
EOS
end
