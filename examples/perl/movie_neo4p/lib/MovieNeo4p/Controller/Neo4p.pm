package MovieNeo4p::Controller::Neo4p;
use Mojo::Base 'Mojolicious::Controller';
use REST::Neo4p;
use strict;
use warnings;

sub movie {
  my $self = shift;
  $self->render(text => "Hey, movie: ".$self->stash('title'));
}

sub search {
  my $self = shift;
  $self->render(text => "Dude, search.");
}

sub graph {
  my $self = shift;
  $self->render(text => "Yowza, graph!");
}

1;
