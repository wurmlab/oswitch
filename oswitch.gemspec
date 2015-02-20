Gem::Specification.new do |s|
  # meta
  s.name        = 'oswitch'
  s.version     = '0.2.0'
  s.authors     = ['Anurag Priyam', 'Bruno Vieira', 'Yannick Wurm']
  s.email       = ['anurag08priyam@gmail.com']
  s.homepage    = 'https://github.com/yeban/oswitch'
  s.license     = 'MIT'

  s.summary     = "Use docker image as the host operating system's user and \
access host operating system's filesystem."
  s.description = <<DESC
Use any docker image as the host operating system's user (same user name, same
uid, same gid, and even the same shell!) and access to host operating system's
filesystem.
DESC

  # dependencies
  s.add_dependency('colorize',    '~> 0.7.5')
  s.required_ruby_version =       '>= 2.0'

  # gem
  s.files         = Dir['lib/**/*'] + Dir['Dockerfiles/**/*']
  s.files         = s.files + ['Gemfile', 'oswitch.gemspec']
  s.files         = s.files + ['README.mkd']
  s.require_paths = ['lib']
  s.executables   = ['oswitch']

end
