
# Also provides ::Base::DBIxClass later on...

package Infobot::Plugin::DataSource::DBIxClass;

	use base qw/Infobot::Plugin::DataSource::Base/; 

	sub load {
	
		my $self = shift;
		
		return $self->require_base( qw/DBIx::Class::Schema::Loader/ );	
		
	}
		
# Connect to the database...

	sub init {

		my $self   = shift;
		my $name   = shift;

		$self->set_name( $name );

	# Options for DBIx..Loader

		$self->loader_options(
			relationships => 1,
			constraint    => $self->{config}->{constraint},
			debug         => 0,
		);
	
		$self->log( 6, "Attempting connection to $self->{config}->{dsn}" );
		
		$self->connection(
			$self->{config}->{dsn},
			$self->{config}->{user},
			$self->{config}->{pass},
		);

	# Try to actually connect...

		$self->storage->ensure_connected();# Dies on failure 

	# Put ourselves in a sensible place in the stash...

		$self->stash( $self->alias => $self );

		return 1; 

	}


package Infobot::Plugin::Query::Base::DBIxClass;

	use strict;
	use warnings;

	use base qw( Infobot::Plugin::Query::Base );

  sub init {

    my $self = shift;
    my $name = shift;

 	# Set our name, and grab in the values from the config file

		$self->set_name( $name );

	# Check the appropriate table exists...

		my $dbh = $self->stash( $self->{config}->{db} );
		unless ( $dbh ) { die "Where did my DB go? $self->{config}->{db}" } 
			
		my $table_name = $self->tablename;
		my $resultset = eval { $dbh->resultset( $table_name ) };

		unless ( $resultset ) {

				$self->log( 2, "Table $table_name not found" );
				$self->log( 2, $@ );
				return 0;

		}

    return 1;

  }

	sub tablename { my $self = shift; return ucfirst( $self->{config}->{table} ) }

	sub dbi { 
		
		my $self = shift; 
		my $dbh = $self->stash( $self->{config}->{db} );
		
		return $dbh->resultset( $self->tablename );

	}
1;
