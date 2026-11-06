#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint clipboard_image_paste_ios.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'clipboard_image_paste_ios'
  s.version          = '0.1.0'
  s.summary          = 'Reads images from UIPasteboard for the clipboard_image_paste Flutter plugin.'
  s.description      = <<-DESC
iOS implementation of the clipboard_image_paste Flutter plugin. Checks for and reads images on UIPasteboard.
                       DESC
  s.homepage         = 'https://github.com/Musab1j/clipboard_image_paste'
  s.license          = { :type => 'BSD', :file => '../LICENSE' }
  s.author           = { 'The clipboard_image_paste Authors' => 'https://github.com/Musab1j/clipboard_image_paste' }
  s.source           = { :http => 'https://github.com/Musab1j/clipboard_image_paste/tree/main/packages/clipboard_image_paste_ios' }
  s.source_files = 'clipboard_image_paste_ios/Sources/clipboard_image_paste_ios/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = {'clipboard_image_paste_ios_privacy' => ['clipboard_image_paste_ios/Sources/clipboard_image_paste_ios/PrivacyInfo.xcprivacy']}
end
