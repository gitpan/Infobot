
package Infobot::Plugin::Query::Karma;

	use strict;

	use base (qw( Infobot::Plugin::Query::Base::DBIxClass ));
	

	sub process {
		
		my $package = shift;
		my $message = shift;
	
		my $text = $message->{message};
	
	# Reverse back-to-front karma

		$text =~ s/\W(--|\+\+)(\(.*?\)|[^(++)(--)\s]+)/$2$1/;
	
	# Retrieving karma

		if ( $message->{message} =~ m/^topten karma??$/) {

			$message->say( 'Best karma: ' . Infobot::Plugin::Core::Karma::DB::topten( 'desc' ) );
			return 1;

		} elsif ( $message->{message} =~ m/^bottomten karma??$/) {

			$message->say( 'Worst karma: ' . Infobot::Plugin::Core::Karma::DB::topten( 'asc' ) );

		} elsif ( $message->{message} =~ m/^(?:karma|score)\s+(?:for\s+)?(.*?)[?\s]*$/ ) {

			my $score = Infobot::Plugin::Query::Karma::DB::get_score( $1 );

			if ( $score == 0 ) {

				$message->say( $1 . ' has neutral karma' );

			} else {
			
				$message->say( $1 . ' has karma of ' . $score );
			
			}
			
			return 1;

		} elsif ( $message->{message} =~ m/^explain\s+(?:karma|score)\s+(?:for\s+)?(.*?)[?\s]*$/ ) {

			$message->say( Infobot::Plugin::Query::Karma::DB::Explain::get_explanation($1) );
			return 1;

		} elsif ( $text =~ m/(\(.*?\)|[^(++)(--)\s]+)(\+\+|--)/ ) {

		# One message per item changed...
			
			my %karma_limit;

			$text =~ s/#\s*(.+)//;
			my $reason = $1;
			
			while ($text =~ s/(\(.*?\)|[^(++)(--)\s]+)(\+\+|--)//) {

				my ( $noun, $verb ) = ( $1, $2 );
			
			# Try and normalise this a little...

				$noun = lc( $noun );
				$noun =~ s/^\((.*)\)$/$1/; # Remove brackets
				$noun =~ s/\s+/ /g;
				$noun =~ s/^ ?(.+?) ?$/$1/;

				next unless $noun;
				next if $karma_limit{ $noun }++;
			
			# Stop people being silly...

				if (! $message->{public} ) {

					$message->say("karma must be done in public!");
					return 1;

				}

				if ( lc( $message->{name} ) =~ m/^$noun[\d_]*$/ ) {

					$message->{public} = 0;
					$message->say("Please don't karma yourself");
					return 1;

				}

				if ( $verb eq '++' ) {

					Infobot::Plugin::Query::Karma::DB::increment( $noun );

					if ( $reason ) {

						Infobot::Plugin::Query::Karma::DB::Explain::add_explanation(
							$noun,
							$message->{name},
							1,
							$reason
						);

					}
					
				} else {
				
					Infobot::Plugin::Query::Karma::DB::decrement( $noun );	
					
					if ( $reason ) {

            Infobot::Plugin::Query::Karma::DB::Explain::add_explanation(
              $noun,
              $message->{name},
              0,
              $reason
            );


					}
					
				}

			}

		}

		return undef;

	}

1;

__DATA__

package Infobot::Plugin::Query::Karma::DB;

	use base qw/DBIx::Class/;
	
	__PACKAGE__->load_components(qw/PK::Auto Core/);
	__PACKAGE__->table('karma');
	__PACKAGE__->add_columns( qw/ id score / );
	__PACKAGE__->set_primary_key( 'id' );

	Infobot::DBI->register_class( Karma => __PACKAGE__ );
	
	sub increment { my $noun = shift; _change_score( $noun, 1  ) }
	sub decrement { my $noun = shift; _change_score( $noun, -1 ) }

	sub get_score {

		my $noun = shift;

		my $object = $self->dbi->resultset('Karma')->find( $noun );

		return 0 unless $object;

		return $object->score;

	}
	
	sub topten {

		my $order = shift;
		my $count = 1;

		return 
			join '; ',
			map { $count++ . '. ' . $_->id . ' (' . $_->score . ')' }
			$self->dbi->resultset('Karma')->search_literal('LENGTH(id) > 1 ORDER BY score ' . $order );

	}
	
	sub _change_score {

		my $noun = shift;
		my $score = shift;

		my $object = $self->dbi->resultset('Karma')->find_or_create( { id => $noun } );	
		$object->score( $object->score + $score );
		$object->update;

	}

package Infobot::Plugin::Query::Karma::DB::Explain;

  use base qw/DBIx::Class/;

  __PACKAGE__->load_components(qw/PK::Auto Core/);
  __PACKAGE__->table('karma_explain');
  __PACKAGE__->add_columns( qw/ id noun name type explanation / );
  __PACKAGE__->set_primary_key( 'id' );

  Infobot::DBI->register_class( KarmaExplain => __PACKAGE__ );	

	sub add_explanation {

		my $noun  = shift;
		my $name  = shift;
		my $score = shift;
		my $explanation = shift;

		return if length( $explanation ) > 20;
		return if length( $explanation ) < 2;

		$score = $score ? 'positive' : 'negative';

		$self->dbi->resultset( 'KarmaExplain' )->create({
			noun => $noun,
			name => $name,
			type => $score,
			explanation => $explanation,
		});

	}

	sub get_explanation {

		my $noun = shift;

		my %return_strings;

		for my $type ( qw( positive negative ) ) {

			my $count;

			$return_strings{ $type } =

				join ', ',

			# Read these from the bottom up, obviously
			
				map  { $_->explanation . ' (' . $_->name . ')' } # Decorate	
				grep { (! $count++ < 2 )       } # Limit to three
				map  { $_->[0]                 } # Remove the dec
				sort { $a->[1] <=> $b->[1]     } # Sort using that element
				map  { [ $_, rand(1) ]         } # Assign a random dec to each element
			
			# Get the results from the DB
				
				$self->dbi->resultset( 'KarmaExplain' )->search({
					noun => $noun,
					type => $type,
				});	

			$return_strings{ $type } = "No explanations" unless $return_strings{ $type };

		}

		my $overall = Infobot::Plugin::Query::Karma::DB::get_score( $noun ); 
		$overall = 'neutral' unless $overall;

		return "Positive: $return_strings{'positive'}; Negative: $return_strings{'negative'}; Overall: $overall";

	}

1;
