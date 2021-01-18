package HeadlessCMSPack::Callback;
use Amazon::S3::Thin;
use HTTP::Request;
use utf8;
use Data::Dumper;
use MT::DataAPI::Resource;
use MT::App::DataAPI;
use MT::DataAPI::Format::JSON;
{
    package MT::App::CMS;
    sub current_api_version { return MT->request( 'data_api_current_version' ) }
}
sub s3upload {
  my ($cb, %params) = @_;

  my $plugin = MT->component('HeadlessCMSPack');
  my $blog_id = 'blog:' . $params{'blog'}->id;
  doLog("HeadlessCMSPack ${blog_id}");
  my $aws_access_key_id = $plugin->get_config_value('aws_access_key_id_blog', $blog_id);
  my $aws_secret_access_key = $plugin->get_config_value('aws_secret_access_key_blog', $blog_id);
  my $region = $plugin->get_config_value('aws_region_blog', $blog_id);
  my $bucket = $plugin->get_config_value('aws_bucket_blog', $blog_id);

  doLog("HeadlessCMSPack ${bucket}");

  $aws_access_key_id = $plugin->get_config_value('aws_access_key_id_system', 'system') unless $aws_access_key_id;
  $aws_secret_access_key = $plugin->get_config_value('aws_secret_access_key_system', 'system') unless $aws_secret_access_key;
  $region = $plugin->get_config_value('aws_region_system', 'system') unless $region;
  $bucket = $plugin->get_config_value('aws_bucket_system', 'system') unless $bucket;

  doLog('HeadlessCMSPack PluginのBucketが設定されていません') unless $bucket;
  return unless $bucket;
  doLog('HeadlessCMSPack PluginのRegionが設定されていません') unless $region;
  return 0 unless $region;
  my $file = $params{'File'};
  my $name  = $params{'Asset'}->file_name;
  my $site_path  = $params{'blog'}->site_path . '/';
  my $relative_path = $file;
  $relative_path =~ s|$site_path||g;
  my $content_type;
  $content_type = 'image/png' if $params{'image_type'} eq 'PNG';
  $content_type = 'image/jpeg' if $params{'image_type'} eq 'JPEG';
  $content_type = 'image/gif' if $params{'image_type'} eq 'GIF';
  $content_type = _contentType($name) unless $content_type;

  my $s3client = Amazon::S3::Thin->new({
    aws_access_key_id     =>  $aws_access_key_id, 
    aws_secret_access_key =>  $aws_secret_access_key, 
    region                =>  $region,
  });
  open(my $fh, "<:raw", $file)
        or die "Can't open < $file: $!";
  my $size = -s $file;
  read($fh, my $content, $size, 0)
        or die "Can't read < $file: $!";
  my $res = $s3client->put_object($bucket, $relative_path, $content , {'Content-Type' => $content_type,});
  doLog("HeadlessCMSPack".$file."をs3にアップロードしました") if $res->is_success;
  doLog("HeadlessCMSPack".$file."をs3にアップロード失敗しました") unless $res->is_success;
}

sub nobuild {
  my ($cb, %args) = @_;

  return 0;
}

sub entrySaveWebhook {
  my ($cb, $app, $obj, $org_obj) = @_;
  my $blog_id = 'blog:' . $obj->blog_id;

  my $plugin = MT->component('HeadlessCMSPack');
  my $version = MT::App::DataAPI::DEFAULT_VERSION();
  MT->request( 'data_api_current_version', $version );
  my $res = MT::DataAPI::Resource->from_object( $obj ) || return '{}';
  my $json =  MT::DataAPI::Format::JSON::serialize($res);
  my $webhook_url = $plugin->get_config_value('entry_save_webhook_url_blog', $blog_id);
  $webhook_url = $plugin->get_config_value('entry_save_webhook_url_system', 'system') unless $webhook_url;

  return unless $webhook_url;
  $ua = LWP::UserAgent->new;

  my $req = HTTP::Request->new( 'POST', $webhook_url);
  $req->header( 'Content-Type' => 'application/json');
  $req->content( $json );
  $ua->request( $req );
}


sub entryDeleteWebhook {
  my ($cb, $app, $obj, $org_obj) = @_;
  my $blog_id = 'blog:' . $obj->blog_id;

  my $plugin = MT->component('HeadlessCMSPack');
  my $version = MT::App::DataAPI::DEFAULT_VERSION();
  MT->request( 'data_api_current_version', $version );
  my $res = MT::DataAPI::Resource->from_object( $obj ) || return '{}';
  my $json =  MT::DataAPI::Format::JSON::serialize($res);
  my $webhook_url = $plugin->get_config_value('entry_delete_webhook_url_blog', $blog_id);
  $webhook_url = $plugin->get_config_value('entry_delete_webhook_url_system', 'system') unless $webhook_url;

  return unless $webhook_url;
  $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new( 'POST', $webhook_url);
  $req->header( 'Content-Type' => 'application/json');
  $req->content( $json );
  $ua->request( $req );
}

sub categorySaveWebhook {
  my ($cb, $app, $obj, $org_obj) = @_;
  my $blog_id = 'blog:' . $obj->blog_id;

  my $plugin = MT->component('HeadlessCMSPack');
  my $version = MT::App::DataAPI::DEFAULT_VERSION();
  MT->request( 'data_api_current_version', $version );
  my $res = MT::DataAPI::Resource->from_object( $obj ) || return '{}';
  my $json =  MT::DataAPI::Format::JSON::serialize($res);
  my $webhook_url = $plugin->get_config_value('category_save_webhook_url_blog', $blog_id);
  $webhook_url = $plugin->get_config_value('category_save_webhook_url_system', 'system') unless $webhook_url;

  return unless $webhook_url;
  $ua = LWP::UserAgent->new;

  my $req = HTTP::Request->new( 'POST', $webhook_url);
  $req->header( 'Content-Type' => 'application/json');
  $req->content( $json );
  $ua->request( $req );
}


sub categoryDeleteWebhook {
  my ($cb, $app, $obj, $org_obj) = @_;
  my $blog_id = 'blog:' . $obj->blog_id;

  my $plugin = MT->component('HeadlessCMSPack');
  my $version = MT::App::DataAPI::DEFAULT_VERSION();
  MT->request( 'data_api_current_version', $version );
  my $res = MT::DataAPI::Resource->from_object( $obj ) || return '{}';
  my $json =  MT::DataAPI::Format::JSON::serialize($res);
  my $webhook_url = $plugin->get_config_value('category_delete_webhook_url_blog', $blog_id);
  $webhook_url = $plugin->get_config_value('category_delete_webhook_url_system', 'system') unless $webhook_url;

  return unless $webhook_url;
  $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new( 'POST', $webhook_url);
  $req->header( 'Content-Type' => 'application/json');
  $req->content( $json );
  $ua->request( $req );
}

sub assetSaveWebhook {
  my ($cb, $app, $obj, $org_obj) = @_;
  my $blog_id = 'blog:' . $obj->blog_id;

  my $plugin = MT->component('HeadlessCMSPack');
  my $version = MT::App::DataAPI::DEFAULT_VERSION();
  MT->request( 'data_api_current_version', $version );
  my $res = MT::DataAPI::Resource->from_object( $obj ) || return '{}';
  my $json =  MT::DataAPI::Format::JSON::serialize($res);
  my $webhook_url = $plugin->get_config_value('asset_save_webhook_url_blog', $blog_id);
  $webhook_url = $plugin->get_config_value('asset_save_webhook_url_system', 'system') unless $webhook_url;

  return unless $webhook_url;
  $ua = LWP::UserAgent->new;

  my $req = HTTP::Request->new( 'POST', $webhook_url);
  $req->header( 'Content-Type' => 'application/json');
  $req->content( $json );
  $ua->request( $req );
}


sub assetDeleteWebhook {
  my ($cb, $app, $obj, $org_obj) = @_;
  my $blog_id = 'blog:' . $obj->blog_id;

  my $plugin = MT->component('HeadlessCMSPack');
  my $version = MT::App::DataAPI::DEFAULT_VERSION();
  MT->request( 'data_api_current_version', $version );
  my $res = MT::DataAPI::Resource->from_object( $obj ) || return '{}';
  my $json =  MT::DataAPI::Format::JSON::serialize($res);
  my $webhook_url = $plugin->get_config_value('asset_delete_webhook_url_blog', $blog_id);
  $webhook_url = $plugin->get_config_value('asset_delete_webhook_url_system', 'system') unless $webhook_url;

  return unless $webhook_url;
  $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new( 'POST', $webhook_url);
  $req->header( 'Content-Type' => 'application/json');
  $req->content( $json );
  $ua->request( $req );
}

sub siteSaveWebhook {
  my ($cb, $app, $obj, $org_obj) = @_;
  my $blog_id = 'blog:' . $obj->id;

  my $plugin = MT->component('HeadlessCMSPack');
  my $version = MT::App::DataAPI::DEFAULT_VERSION();
  MT->request( 'data_api_current_version', $version );
  my $res = MT::DataAPI::Resource->from_object( $obj ) || return '{}';
  my $json =  MT::DataAPI::Format::JSON::serialize($res);
  my $webhook_url = $plugin->get_config_value('site_save_webhook_url_blog', $blog_id);
  $webhook_url = $plugin->get_config_value('site_save_webhook_url_system', 'system') unless $webhook_url;

  return unless $webhook_url;
  $ua = LWP::UserAgent->new;

  my $req = HTTP::Request->new( 'POST', $webhook_url);
  $req->header( 'Content-Type' => 'application/json');
  $req->content( $json );
  $ua->request( $req );
}


sub siteDeleteWebhook {
  my ($cb, $app, $obj, $org_obj) = @_;
  my $blog_id = 'blog:' . $obj->id;

  my $plugin = MT->component('HeadlessCMSPack');
  my $version = MT::App::DataAPI::DEFAULT_VERSION();
  MT->request( 'data_api_current_version', $version );
  my $res = MT::DataAPI::Resource->from_object( $obj ) || return '{}';
  my $json =  MT::DataAPI::Format::JSON::serialize($res);
  my $webhook_url = $plugin->get_config_value('site_delete_webhook_url_blog', $blog_id);
  $webhook_url = $plugin->get_config_value('site_delete_webhook_url_system', 'system') unless $webhook_url;

  return unless $webhook_url;
  $ua = LWP::UserAgent->new;
  my $req = HTTP::Request->new( 'POST', $webhook_url);
  $req->header( 'Content-Type' => 'application/json');
  $req->content( $json );
  $ua->request( $req );
}

sub _contentType {
  my ($file) = @_;
  return 'image/jpeg' if $file =~ /\.jpg$/;
  return 'image/png' if $file =~ /\.png$/;
  return 'image/gif' if $file =~ /\.gif$/;
  return 'image/svg+xml' if $file =~ /\.svg$/;
  return 'application/octet-stream';
}

sub doLog {
    my ($msg, $class) = @_;
    return unless defined($msg);

    require MT::Log;
    my $log = new MT::Log;
    $log->message($msg);
    $log->level(MT::Log::DEBUG());
    $log->class($class) if $class;
    $log->save or die $log->errstr;
}
1;