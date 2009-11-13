#!perl

use strict;
use warnings;

use t::Util qw( require_plasxom require_plugin $example );
use Test::More tests => 1;

require_plasxom;
require_plugin('simpleamazon');

my $plugin  = plasxom::plugin::simpleamazon->new( config => { locale => 'jp', apikey => 'X', secret => 'X' }, state => $example->subdir('plugin/simpleamazon/state') );
my $xml     = $example->file('plugin/simpleamazon/4062836637.xml')->slurp;

my $ret = $plugin->parse( $xml );

is_deeply(
    $ret,
    {
        ASIN            => '4062836637',

        DetailPageURL   => 'http://www.amazon.co.jp/%E5%82%B7%E7%89%A9%E8%AA%9E-%E8%AC%9B%E8%AB%87%E7%A4%BEBOX-%E8%A5%BF%E5%B0%BE-%E7%B6%AD%E6%96%B0/dp/4062836637%3FSubscriptionId%3D1F1FPGVA4H8B3RMXPA82%26tag%3Dws%26linkCode%3Dxm2%26camp%3D2025%26creative%3D165953%26creativeASIN%3D4062836637',

        AddToWishlist       => 'http://www.amazon.co.jp/gp/registry/wishlist/add-item.html%3Fasin.0%3D4062836637%26SubscriptionId%3D1F1FPGVA4H8B3RMXPA82%26tag%3Dws%26linkCode%3Dxm2%26camp%3D2025%26creative%3D5143%26creativeASIN%3D4062836637',
        TellAFriend         => 'http://www.amazon.co.jp/gp/pdp/taf/4062836637%3FSubscriptionId%3D1F1FPGVA4H8B3RMXPA82%26tag%3Dws%26linkCode%3Dxm2%26camp%3D2025%26creative%3D5143%26creativeASIN%3D4062836637',
        AllCustomerReviews  => 'http://www.amazon.co.jp/review/product/4062836637%3FSubscriptionId%3D1F1FPGVA4H8B3RMXPA82%26tag%3Dws%26linkCode%3Dxm2%26camp%3D2025%26creative%3D5143%26creativeASIN%3D4062836637',
        AllOffers           => 'http://www.amazon.co.jp/gp/offer-listing/4062836637%3FSubscriptionId%3D1F1FPGVA4H8B3RMXPA82%26tag%3Dws%26linkCode%3Dxm2%26camp%3D2025%26creative%3D5143%26creativeASIN%3D4062836637',

        SwatchImage         => 'http://ecx.images-amazon.com/images/I/5135RS9KhDL._SL30_.jpg',
        SmallImage          => 'http://ecx.images-amazon.com/images/I/5135RS9KhDL._SL75_.jpg',
        ThumbnailImage      => 'http://ecx.images-amazon.com/images/I/5135RS9KhDL._SL75_.jpg',
        TinyImage           => 'http://ecx.images-amazon.com/images/I/5135RS9KhDL._SL110_.jpg',
        MediumImage         => 'http://ecx.images-amazon.com/images/I/5135RS9KhDL._SL160_.jpg',
        LargeImage          => 'http://ecx.images-amazon.com/images/I/5135RS9KhDL.jpg',

        Author              => '西尾 維新',
        Binding             => '単行本（ソフトカバー）',
        ListPrice           => '1365',
        Manufacturer        => '講談社',
        ReleaseDate         => '2008-05-08',
        PublicationDate     => '2008-05-08',
        Title               => '傷物語 (講談社BOX)',

        LowestUsedPrice     => '1000',
        Availability        => '在庫あり。',

        Timestamp           => '2009-11-12T05:48:29Z',
    }
);