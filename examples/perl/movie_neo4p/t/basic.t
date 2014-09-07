use Mojo::Base -strict;
use lib '../lib';
use Test::More;
use Test::Mojo;
use Try::Tiny;

use_ok('MovieNeo4p');
use_ok('MovieNeo4p::Controller::Neo4p');
my $t;
my $neo4j_available = 1;
try {
 $t = Test::Mojo->new('MovieNeo4p');
} catch {
  $neo4j_available = 0;
  fail $_;
  done_testing;
};

SKIP : {
  skip 'Neo4j server not available, skipping tests', 1 unless $neo4j_available;
  $t->get_ok('/')->status_is(200)->header_is('Content-Type' => 'application/json');
  $t->json_like('/app' => qr/Movie-Neo4p/)->json_like('/endpoints/0',qr/movie/)->json_like('/endpoints/1',qr/search/)->json_like('/endpoints/2',qr/graph/);

  $t->get_ok('/movie')->status_is(400);
  $t->get_ok('/search')->status_is(400);
  $t->get_ok('/movie/The Matrix')->status_is(200)->header_is('Content-Type' => 'application/json')->json_has('/title')->json_has('/cast');
  $t->get_ok('/movie/The%20Matrix')->status_is(200)->header_is('Content-Type' => 'application/json')->json_has('/title')->json_has('/cast');
  $t->get_ok('/search?q=matrix')->status_is(200)->header_is('Content-Type' => 'application/json')->json_has('/0/movie/released')->json_has('/0/movie/tagline')->json_has('/0/movie/title');
}

done_testing();
