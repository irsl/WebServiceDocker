package WebService::Docker::API;

=head1 NAME

WebService::Docker::API - Minimalistic implementation of the Docker proto inspired by Net::Docker
=cut

use warnings;
use strict;
use LWP::UserAgent;
use URI;
use JSON::XS;

use vars qw($VERSION);

$VERSION     = 1.00;

sub new {
    my $class = shift;
    my $docker_socket = shift || "http:/var/run/docker.sock/";

    if ( $docker_socket !~ m!http://! ) {
        require LWP::Protocol::http::SocketUnixAlt;
        LWP::Protocol::implementor( http => 'LWP::Protocol::http::SocketUnixAlt' );
    }
    my $ua = LWP::UserAgent->new;
    my $json = JSON::XS->new;

    my $obj = {
      _docker_socket => $docker_socket,
      _ua => $ua,
      _json => $json,
    };
    bless $obj, $class;

    return $obj;
}

sub _uri {
    my ($self, $uri, %options) = @_;
    my $re = URI->new($self->{'_docker_socket'} . $uri);
    $re->query_form(%options);
    return $re;
}

sub _byRes {
  my $self = shift;
  my $res = shift;
  my $body = shift;

  my $json = $self->{'_json'};

    if (($res->content_type eq 'application/json') && ($body) && ($json)) {
        return $json->incr_parse($body);
    }
}

sub _body_callback_wrapper {
     my ($self, $data, $response, $protocol) = @_;

  my $event = $self->_byRes($response, $data);
  while ( ($event) ) {
    $self->{'_body_callback'}->($event);
    $event = $self->_byRes($response);
  }
}

sub get {
  my $self = shift;
  my $uri = shift;
  my $callback = shift;

  my $urio = $self->_uri($uri);
  $self->{'_json'}->incr_reset();
  my $res;
  if ( ($callback) ) {
    $self->set_body_callback($callback);
    my $cb  = sub { $self->_body_callback_wrapper(@_);  };
    $res = $self->{'_ua'}->get($urio, ':content_cb' => $cb);
  } else {
    $res = $self->{'_ua'}->get($urio);
  }

  die "Docker request was unsuccessful:\n".$res->as_string if(!$res->is_success);

  return $self->_byRes($res, $res->decoded_content);
}

sub post {
  my $self = shift;
  my $uri = shift;
  my %options = shift;

  my $cb  = sub { $self->_body_callback_wrapper(@_);  };

  my $input = encode_json(\%options);
  my $res = $self->{'_body_callback'} ?
         $self->_ua->post($self->_uri($uri), ':content_cb' => $cb, 'Content-Type' => 'application/json', Content => $input) :
         $self->_ua->post($self->_uri($uri), 'Content-Type' => 'application/json', Content => $input);

  return $self->_byRes($res);
}

sub container_info {
  my $self = shift;
  my $container = shift;
  return $self->get("/containers/$container/json");
}

sub containers {
  my $self = shift;
  return $self->get("/containers/json");
}
sub networks {
  my $self = shift;
  return $self->get("/networks");
}

sub set_body_callback {
  my ($self, $callback) = @_;
  $self->{'_body_callback'} = $callback;
}

sub set_headers_callback {
  my ($self, $callback) = @_;
  $self->{'_ua'}->add_handler("response_header"=>$callback);
}

sub events {
  my ($self, $callback) = @_;
  return $self->get('/events',$callback);
}

1;
