package MovieNeo4p::Controller::Neo4p;
use Mojo::Base 'Mojolicious::Controller';
use REST::Neo4p;
use JSON;
use Try::Tiny;
use Data::Dumper;
use strict;
use warnings;

my %Q = (
  movie => REST::Neo4p::Query->new(<<MOVIE),
MATCH (movie:Movie {title:{title}})
 OPTIONAL MATCH (movie)<-[r]-(person:Person)
 RETURN movie.title as title,
       collect({name:person.name,
                job:head(split(lower(type(r)),'_')),
                role:r.roles}) as cast LIMIT 1
MOVIE

  search => REST::Neo4p::Query->new(<<SEARCH),
MATCH (movie:Movie)
 WHERE movie.title =~ {query}
 RETURN movie
SEARCH

  graph => REST::Neo4p::Query->new(<<GRAPH)
MATCH (m:Movie)<-[:ACTED_IN]-(a:Person)
 RETURN m.title as movie, collect(a.name) as cast
 LIMIT {limit}
GRAPH

);
while ( my ($k,$v) = each %Q ) {
  $v->{ResponseAsObjects} = 0;
}

sub movie {
  my $self = shift;
  my $title = $self->stash('title');
  unless ($title) {
    $self->render(text => "No title provided", format=>'txt', status => 400);
    return;
  }
  try {
    $Q{movie}->execute(title => $title);
    my $row = $Q{movie}->fetch;
    $Q{movie}->finish;
    if ($row) {
      $self->render(text => encode_json { title => $$row[0], cast => $$row[1] }, 
		    format => 'json');
    }
    else {
      $self->render(text=>'',status=>404);
    }
  } catch {
    if (ref) {
      $self->render(text => $_->message, status => $_->code || 500);
    }
    else {
      $self->render(text => $_, format=>'txt', status => 500);
    }
  };
  return;
}

sub search {
  my $self = shift;
  my $query = $self->param('q');
  unless ($query) {
    $self->render(text => "No query provided", format=>'txt', status => 400);
    return;
  }
  try {
    $Q{search}->execute(query => $query);
    my $ret;
    while (my $row = $Q{search}->fetch) {
      delete $$row[0]->{_node};
      push @{$ret}, { movie => $$row[0] };
    }
    $Q{search}->finish;
    if ($ret) {
      $self->render( text => encode_json $ret, format => 'json' );
    }
    else {
      $self->render(text=>'',status=>404);
    }
  } catch {
    if (ref) {
      $self->render(text => $_->message, format=>'txt',status => 
		      ref =~ /Neo4p/ ? $_->code || 500 : 500);
    }
    else {
      $self->render(text => $_, format=>'txt', status => 500);
    }
  }
}

sub graph {
  my $self = shift;
  $self->render(text => "Yowza, graph!");
}

1;
