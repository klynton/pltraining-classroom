class classroom::agent::git {
  assert_private('This class should not be called directly')

  case $::osfamily {
    'windows' : {
      $environment = undef
      $path        = 'C:/Program Files (x86)/Git/bin'
      $sshpath     = 'C:/Program Files (x86)/Git/.ssh'
    }
    default   : {
      $environment = 'HOME=/root'
      $path        = '/usr/bin:/bin:/user/sbin:/usr/sbin'
      $sshpath     = '/root/.ssh'
    }
  }
  Exec {
    environment => $environment,
    path        => $path,
  }

  if $::osfamily == 'windows'{
    require classroom::windows::chocolatey

    package { ['git', 'kdiff3']:
      ensure   => present,
      before   => [ File[$sshpath], Exec['generate_key'] ],
      provider => 'chocolatey',
    }

    file { 'C:/Users/Administrator/.ssh/':
      ensure  => directory,
      source  => $sshpath,
      recurse => true,
      require => [File[$sshpath],Exec['generate_key'],User['Administrator']],
    }

    windows_env { 'PATH=C:\Program Files (x86)\Git\bin': }
  }
  else {
    class { '::git':
      before => [ File[$sshpath], Exec['generate_key'] ],
    }
  }

  file { $sshpath:
    ensure => directory,
    mode   => '0600',
  }

  exec { 'generate_key':
    command => "ssh-keygen -t rsa -N '' -f '${sshpath}/id_rsa'",
    creates => "${sshpath}/id_rsa",
    require => File[$sshpath],
  }

  exec { "git config --global user.name '${classroom::params::machine_name}'":
    unless  => 'git config --global user.name',
    require => Exec['generate_key'],
  }

  exec { "git config --global user.email ${classroom::params::machine_name}@puppetlabs.vm":
    unless  => 'git config --global user.email',
    require => Exec['generate_key'],
  }

  exec { 'git config --global color.ui always':
    unless  => 'git config --global color.ui',
    require => Exec['generate_key'],
  }

}
