# Set up the master with user accounts, environments, etc
class classroom::master {
  assert_private('This class should not be called directly')

  File {
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  # Add the installer files for 32bit agents
  # These files are cached by the build, so this will work offline
  include pe_repo::platform::el_6_i386

  # Ensure the environment cache is disabled and restart if needed
  ini_setting {'environment timeout':
    ensure  => present,
    path    => "${classroom::confdir}/puppet.conf",
    section => 'main',
    setting => 'environment_timeout',
    value   => '0',
    notify  => Service['pe-puppetserver'],
  }

  # Anything that needs to be top scope
  file { "${classroom::codedir}/environments/production/manifests/classroom.pp":
    ensure => file,
    source => 'puppet:///modules/classroom/classroom.pp',
  }

  # if configured to do so, configure repos & environments on the master. This
  # overrides the resource in the puppet_enterprise module and allows us to have
  # different users updating their own repositories.
  if $classroom::managerepos {
    File <| title == "${classroom::codedir}/environments" |> {
      mode => '1777',
    }

    include classroom::master::repositories
  }

  # Ensure that time is set appropriately
  include classroom::master::time

  # unselect all nodes in Live Management by default
  #include classroom::console::patch

  # Now create all of the users who've checked in
  Classroom::User <<||>>

  # Add autoteam yaml
  include classroom::master::autoteam
}
