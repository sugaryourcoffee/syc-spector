Gem::Specification.new do |s|
  s.name         = "syc-spector"
  s.summary      = 
    "Analyze a file and extract values matching a provided pattern.\n \
     Allow to sort, remove double and manually fix values."
  s.description  = File.read(File.join(File.dirname(__FILE__), 'README'))
  s.requirements = ['No requirements']
  s.version      = "0.0.2"
  s.author       = "Pierre Sugar"
  s.email        = "pierre@sugaryourcoffee.de"
  s.homepage     = "http://syc.dyndns.org/drupal"
  s.platform     = Gem::Platform::RUBY
  s.required_ruby_version = '>=1.9'
  s.files        = Dir['**/**']
  s.executables  = ['sycspector']
  s.test_files   = Dir['test/test*.rb']
  s.has_rdoc     = true
end
