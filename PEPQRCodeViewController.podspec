
Pod::Spec.new do |s|

    s.name            = 'PEPQRCodeViewController'

    s.version         = '0.0.4'

    s.summary         = 'PEP二维码扫描器'

    s.license         = 'MIT'

    s.homepage        = 'https://github.com/PEPDigitalPublishing/PEPQRCodeViewController'

    s.author          = { '崔冉' => 'cuir@pep.com.cn' }

    s.platform        = :ios, '8.0'

    s.source          = { :svn => 'https://github.com/PEPDigitalPublishing/PEPQRCodeViewController' }

    s.source_files    = '*.{h,m}'

    s.frameworks      = 'Foundation', 'UIKit'

end
