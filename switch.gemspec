Gem::Specification.new do |s|
  # meta
  s.name        = 'switch'
  s.version     = '0.0.1'
  s.authors     = ['Anurag Priyam']
  s.email       = ['anurag08priyam@gmail.com']
  s.homepage    = 'https://github.com/yeban/switch'
  s.license     = 'undefined'

  s.summary     = 'Easy access to Bioinformatics software!'
  s.description = <<DESC
Makes available complex Genomics software (even BioLinux!) in just one command.
The setup is guaranteed to be reproducible and shareable.
DESC

  # dependencies
  s.add_dependency('colorize',    '~> 0.7.5')

  # gem
  s.files         = Dir['lib/**/*'] + Dir['Dockerfiles/**/*']
  s.files         = s.files + ['Gemfile', 'switch.gemspec']
  s.files         = s.files + ['README.mkd']
  s.require_paths = ['lib']
  s.executables   = ['switch']
end
