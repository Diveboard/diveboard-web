-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               5.5.35-0+wheezy1-log - (Debian)
-- Server OS:                    debian-linux-gnu
-- HeidiSQL Version:             9.4.0.5125
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;


-- Dumping database structure for diveboard
CREATE DATABASE IF NOT EXISTS `diveboard` /*!40100 DEFAULT CHARACTER SET latin1 */;
USE `diveboard`;

-- Dumping structure for table diveboard.activities
CREATE TABLE IF NOT EXISTS `activities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tag` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `dive_id` int(11) DEFAULT NULL,
  `spot_id` int(11) DEFAULT NULL,
  `location_id` int(11) DEFAULT NULL,
  `region_id` int(11) DEFAULT NULL,
  `country_id` int(11) DEFAULT NULL,
  `shop_id` int(11) DEFAULT NULL,
  `picture_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_activities_on_user_id` (`user_id`),
  KEY `index_activities_on_dive_id` (`dive_id`),
  KEY `index_activities_on_spot_id` (`spot_id`),
  KEY `index_activities_on_location_id` (`location_id`),
  KEY `index_activities_on_region_id` (`region_id`),
  KEY `index_activities_on_country_id` (`country_id`),
  KEY `index_activities_on_picture_id` (`picture_id`),
  KEY `index_activities_on_shop_id` (`shop_id`),
  KEY `index_activities_all` (`tag`,`user_id`,`dive_id`,`spot_id`,`location_id`,`region_id`,`country_id`,`shop_id`,`picture_id`)
) ENGINE=InnoDB AUTO_INCREMENT=326015 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.activity_followings
CREATE TABLE IF NOT EXISTS `activity_followings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `follower_id` int(11) NOT NULL,
  `exclude` tinyint(1) NOT NULL DEFAULT '0',
  `tag` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `dive_id` int(11) DEFAULT NULL,
  `spot_id` int(11) DEFAULT NULL,
  `location_id` int(11) DEFAULT NULL,
  `region_id` int(11) DEFAULT NULL,
  `country_id` int(11) DEFAULT NULL,
  `shop_id` int(11) DEFAULT NULL,
  `picture_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_activities_following_all` (`follower_id`,`tag`,`user_id`,`dive_id`,`spot_id`,`location_id`,`region_id`,`country_id`,`shop_id`,`picture_id`)
) ENGINE=InnoDB AUTO_INCREMENT=38298 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.advertisements
CREATE TABLE IF NOT EXISTS `advertisements` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `ended_at` datetime DEFAULT NULL,
  `deleted` tinyint(1) NOT NULL DEFAULT '0',
  `title` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `text` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `lat` float DEFAULT NULL,
  `lng` float DEFAULT NULL,
  `picture_id` int(11) NOT NULL,
  `external_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `local_divers` tinyint(1) NOT NULL DEFAULT '0',
  `frequent_divers` tinyint(1) NOT NULL DEFAULT '0',
  `exploring_divers` tinyint(1) NOT NULL DEFAULT '0',
  `moderate_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_advertisements_on_user_id` (`user_id`),
  KEY `index_advertisements_on_lat_and_lng` (`lat`,`lng`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.albums
CREATE TABLE IF NOT EXISTS `albums` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `kind` enum('dive','wallet','trip','blog','shop_ads','avatar','shop_cover','shop_gallery') COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_albums_on_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=229082 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.api_keys
CREATE TABLE IF NOT EXISTS `api_keys` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `comment` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_api_keys_on_key` (`key`),
  KEY `index_api_keys_on_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.api_throttle
CREATE TABLE IF NOT EXISTS `api_throttle` (
  `lookup` varchar(255) NOT NULL DEFAULT '',
  `count_noauth` int(10) DEFAULT NULL,
  `count_auth` int(11) DEFAULT '0',
  PRIMARY KEY (`lookup`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.areas
CREATE TABLE IF NOT EXISTS `areas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `minLat` float DEFAULT NULL,
  `minLng` float DEFAULT NULL,
  `maxLat` float DEFAULT NULL,
  `maxLng` float DEFAULT NULL,
  `elevation` int(11) DEFAULT NULL,
  `geonames_core_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `january` int(11) DEFAULT NULL,
  `february` int(11) DEFAULT NULL,
  `march` int(11) DEFAULT NULL,
  `april` int(11) DEFAULT NULL,
  `may` int(11) DEFAULT NULL,
  `june` int(11) DEFAULT NULL,
  `july` int(11) DEFAULT NULL,
  `august` int(11) DEFAULT NULL,
  `september` int(11) DEFAULT NULL,
  `october` int(11) DEFAULT NULL,
  `november` int(11) DEFAULT NULL,
  `december` int(11) DEFAULT NULL,
  `url_name` varchar(255) DEFAULT NULL,
  `active` tinyint(1) DEFAULT '0',
  `favorite_picture_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_areas_on_coordinate_and_active` (`minLat`,`maxLat`,`minLng`,`maxLng`,`active`),
  KEY `index_areas_on_geonames_core_id` (`geonames_core_id`),
  KEY `index_areas_on_url_name` (`url_name`)
) ENGINE=InnoDB AUTO_INCREMENT=284 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.area_categories
CREATE TABLE IF NOT EXISTS `area_categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `area_id` int(11) DEFAULT NULL,
  `category` varchar(255) DEFAULT NULL,
  `count` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_area_categories_on_area_id` (`area_id`),
  KEY `index_area_categories_on_category_and_count` (`category`,`count`)
) ENGINE=InnoDB AUTO_INCREMENT=2320 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.auth_tokens
CREATE TABLE IF NOT EXISTS `auth_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `token` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `expires` datetime NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `api_key` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_auth_tokens_on_token` (`token`),
  KEY `index_auth_tokens_on_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=128052 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.baskets
CREATE TABLE IF NOT EXISTS `baskets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `shop_id` int(11) DEFAULT NULL,
  `comment` text,
  `note_from_shop` text,
  `in_reply_to_type` varchar(255) DEFAULT NULL,
  `in_reply_to_id` int(11) DEFAULT NULL,
  `status` varchar(255) DEFAULT 'open',
  `delivery_address` text,
  `paypal_fees` float DEFAULT NULL,
  `paypal_fees_currency` varchar(255) DEFAULT NULL,
  `diveboard_fees` float DEFAULT NULL,
  `diveboard_fees_currency` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `paypal_order_id` varchar(25) DEFAULT NULL,
  `paypal_order_date` datetime DEFAULT NULL,
  `paypal_auth_id` varchar(25) DEFAULT NULL,
  `paypal_auth_date` datetime DEFAULT NULL,
  `paypal_capture_id` varchar(25) DEFAULT NULL,
  `paypal_capture_date` datetime DEFAULT NULL,
  `paypal_refund_id` varchar(25) DEFAULT NULL,
  `paypal_refund_date` datetime DEFAULT NULL,
  `paypal_issue` varchar(2048) DEFAULT NULL,
  `paypal_attention` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_baskets_on_user_id_and_shop_id_and_paypal_order_date` (`user_id`,`shop_id`,`paypal_order_date`),
  KEY `index_baskets_on_shop_id_and_user_id_and_paypal_order_date` (`shop_id`,`user_id`,`paypal_order_date`)
) ENGINE=InnoDB AUTO_INCREMENT=675 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.basket_histories
CREATE TABLE IF NOT EXISTS `basket_histories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `basket_id` int(11) NOT NULL,
  `new_status` varchar(255) DEFAULT NULL,
  `detail` text NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_basket_histories_on_basket_id` (`basket_id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.basket_items
CREATE TABLE IF NOT EXISTS `basket_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `basket_id` int(11) DEFAULT NULL,
  `good_to_sell_id` int(11) DEFAULT NULL,
  `good_to_sell_archive` text,
  `quantity` int(11) DEFAULT NULL,
  `price` float DEFAULT NULL,
  `tax` float DEFAULT NULL,
  `total` float DEFAULT NULL,
  `currency` varchar(255) DEFAULT NULL,
  `details` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deposit_option` tinyint(1) NOT NULL DEFAULT '0',
  `deposit` float DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_basket_items_on_basket_id` (`basket_id`),
  KEY `index_basket_items_on_good_to_sell_id` (`good_to_sell_id`)
) ENGINE=InnoDB AUTO_INCREMENT=352 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.blog_categories
CREATE TABLE IF NOT EXISTS `blog_categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `blob` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_blog_categories_on_blob` (`blob`),
  KEY `index_blog_categories_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.blog_posts
CREATE TABLE IF NOT EXISTS `blog_posts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `blog_category_id` int(11) DEFAULT '1',
  `user_id` int(11) DEFAULT NULL,
  `blob` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `published` tinyint(1) DEFAULT '0',
  `published_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `wordpress_article` tinyint(1) DEFAULT '0',
  `flag_moderate_private_to_public` tinyint(1) DEFAULT '0',
  `comments_question` tinyint(1) DEFAULT '0',
  `fb_graph_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `delta` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `index_blog_posts_on_blob` (`blob`),
  KEY `index_blog_posts_on_user_id_and_published_at` (`user_id`,`published_at`),
  KEY `index_blog_posts_on_published_and_published_at` (`published`,`published_at`),
  KEY `index_blog_posts_on_delta` (`delta`)
) ENGINE=InnoDB AUTO_INCREMENT=529 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.cloud_objects
CREATE TABLE IF NOT EXISTS `cloud_objects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `bucket` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `path` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `etag` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `size` int(11) NOT NULL,
  `meta` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=890079 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.content_flags
CREATE TABLE IF NOT EXISTS `content_flags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `data` text COLLATE utf8_unicode_ci,
  `user_id` int(11) DEFAULT NULL,
  `object_id` int(11) DEFAULT NULL,
  `object_type` enum('Spot','Country','Location','Region','BlogPost','Wiki') COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.countries
CREATE TABLE IF NOT EXISTS `countries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ccode` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `blob` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `nesw_bounds` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `best_pic_ids` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ccode` (`ccode`),
  KEY `index_countries_on_blob` (`blob`)
) ENGINE=InnoDB AUTO_INCREMENT=257 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.countries_regions
CREATE TABLE IF NOT EXISTS `countries_regions` (
  `country_id` int(11) DEFAULT NULL,
  `region_id` int(11) DEFAULT NULL,
  KEY `index_countries_regions_on_country_id_and_region_id` (`country_id`,`region_id`),
  KEY `region_id` (`region_id`,`country_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.delayed_jobs
CREATE TABLE IF NOT EXISTS `delayed_jobs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `priority` int(11) DEFAULT '0',
  `attempts` int(11) DEFAULT '0',
  `handler` longtext COLLATE utf8_unicode_ci,
  `last_error` text COLLATE utf8_unicode_ci,
  `run_at` datetime DEFAULT NULL,
  `locked_at` datetime DEFAULT NULL,
  `failed_at` datetime DEFAULT NULL,
  `locked_by` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `queue` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `locale` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `alert_ignore` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `failed_at` (`failed_at`)
) ENGINE=InnoDB AUTO_INCREMENT=44362332 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.disqus_comments
CREATE TABLE IF NOT EXISTS `disqus_comments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `comment_id` varchar(255) DEFAULT NULL,
  `thread_id` varchar(255) DEFAULT NULL,
  `thread_link` varchar(255) DEFAULT NULL,
  `forum_id` varchar(255) DEFAULT NULL,
  `parent_comment_id` varchar(255) DEFAULT NULL,
  `body` text,
  `author_name` varchar(255) DEFAULT NULL,
  `author_email` varchar(255) DEFAULT NULL,
  `author_url` varchar(255) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `source_type` varchar(255) DEFAULT NULL,
  `source_id` int(11) DEFAULT NULL,
  `diveboard_id` int(11) DEFAULT NULL,
  `connections` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_disqus_comments_on_comment_id` (`comment_id`),
  KEY `index_disqus_comments_on_source_type_and_source_id` (`source_type`,`source_id`)
) ENGINE=InnoDB AUTO_INCREMENT=951 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.dives
CREATE TABLE IF NOT EXISTS `dives` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `time_in` datetime NOT NULL DEFAULT '2011-01-01 00:00:00',
  `duration` int(11) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` bigint(20) NOT NULL,
  `graph_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `spot_id` int(11) NOT NULL DEFAULT '1',
  `maxdepth` decimal(8,3) NOT NULL DEFAULT '0.000',
  `notes` text COLLATE utf8_unicode_ci,
  `temp_surface` float DEFAULT NULL,
  `temp_bottom` float DEFAULT NULL,
  `favorite_picture` int(11) DEFAULT NULL,
  `privacy` int(11) NOT NULL DEFAULT '0',
  `safetystops` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `divetype` text COLLATE utf8_unicode_ci,
  `favorite` tinyint(1) DEFAULT NULL,
  `uploaded_profile_id` int(11) DEFAULT NULL,
  `uploaded_profile_index` int(11) DEFAULT NULL,
  `buddies` text COLLATE utf8_unicode_ci,
  `visibility` enum('bad','average','good','excellent') COLLATE utf8_unicode_ci DEFAULT NULL,
  `water` enum('salt','fresh') COLLATE utf8_unicode_ci DEFAULT NULL,
  `altitude` float DEFAULT NULL,
  `weights` float DEFAULT NULL,
  `dan_data` longtext COLLATE utf8_unicode_ci,
  `current` enum('none','light','medium','strong','extreme') COLLATE utf8_unicode_ci DEFAULT NULL,
  `dan_data_sent` longtext COLLATE utf8_unicode_ci,
  `number` int(11) DEFAULT NULL,
  `graph_lint` datetime DEFAULT NULL,
  `shop_id` int(11) DEFAULT NULL,
  `guide` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `trip_id` int(11) DEFAULT NULL,
  `album_id` int(11) DEFAULT NULL,
  `score` int(11) NOT NULL DEFAULT '-100',
  `maxdepth_value` float DEFAULT NULL,
  `maxdepth_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `altitude_value` float DEFAULT NULL,
  `altitude_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `temp_bottom_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `temp_bottom_value` float DEFAULT NULL,
  `temp_surface_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `temp_surface_value` float DEFAULT NULL,
  `weights_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `weights_value` float DEFAULT NULL,
  `delta` tinyint(1) NOT NULL DEFAULT '1',
  `surface_interval` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_dives_on_user_id_and_time_in` (`user_id`,`time_in`),
  KEY `index_dives_on_spot_id_and_time_in` (`spot_id`,`time_in`),
  KEY `index_dives_on_time_in` (`time_in`),
  KEY `uploaded_profile_id` (`uploaded_profile_id`),
  KEY `index_dives_on_shop_id` (`shop_id`),
  KEY `index_dives_on_album_id` (`album_id`),
  KEY `index_dives_on_score` (`score`),
  KEY `index_dives_on_trip_id` (`trip_id`),
  KEY `index_dives_on_delta` (`delta`)
) ENGINE=InnoDB AUTO_INCREMENT=365227 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.dives_buddies
CREATE TABLE IF NOT EXISTS `dives_buddies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dive_id` int(11) NOT NULL,
  `buddy_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `buddy_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_dives_buddies_on_dive_id` (`dive_id`),
  KEY `index_dives_buddies_on_buddy_id_and_buddy_type` (`buddy_id`,`buddy_type`)
) ENGINE=InnoDB AUTO_INCREMENT=144001 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.dives_eolcnames
CREATE TABLE IF NOT EXISTS `dives_eolcnames` (
  `dive_id` int(11) DEFAULT NULL,
  `sname_id` int(11) DEFAULT NULL,
  `cname_id` int(11) DEFAULT NULL,
  KEY `index_dives_eolcnames_on_dive_id` (`dive_id`),
  KEY `index_dives_eolcnames_on_cname_id` (`cname_id`),
  KEY `index_dives_eolcnames_on_sname_id` (`sname_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.dives_fish
CREATE TABLE IF NOT EXISTS `dives_fish` (
  `dive_id` int(11) DEFAULT NULL,
  `fish_id` int(11) DEFAULT NULL,
  KEY `index_dives_fish_on_dive_id` (`dive_id`),
  KEY `index_dives_fish_on_fish_id` (`fish_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.dive_gears
CREATE TABLE IF NOT EXISTS `dive_gears` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dive_id` int(11) NOT NULL,
  `manufacturer` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `model` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `featured` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `category` enum('BCD','Boots','Computer','Compass','Camera','Cylinder','Dive skin','Dry suit','Fins','Gloves','Hood','Knife','Light','Lift bag','Mask','Other','Rebreather','Regulator','Scooter','Wet suit') COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_dive_gears_on_dive_id` (`dive_id`)
) ENGINE=InnoDB AUTO_INCREMENT=14750 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.dive_reviews
CREATE TABLE IF NOT EXISTS `dive_reviews` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dive_id` int(11) NOT NULL,
  `name` varchar(255) NOT NULL,
  `mark` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_dive_reviews_on_dive_id` (`dive_id`)
) ENGINE=InnoDB AUTO_INCREMENT=179634 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.dive_using_user_gears
CREATE TABLE IF NOT EXISTS `dive_using_user_gears` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_gear_id` int(11) NOT NULL,
  `dive_id` int(11) NOT NULL,
  `featured` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_dive_using_user_gears_on_user_gear_id` (`user_gear_id`),
  KEY `index_dive_using_user_gears_on_dive_id` (`dive_id`)
) ENGINE=InnoDB AUTO_INCREMENT=708617 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.emails_marketing
CREATE TABLE IF NOT EXISTS `emails_marketing` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `target_id` int(11) DEFAULT NULL,
  `target_type` varchar(255) DEFAULT NULL,
  `recipient_id` int(11) DEFAULT NULL,
  `recipient_type` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `content` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_emails_marketing_on_email` (`email`),
  KEY `index_emails_marketing_on_content` (`content`)
) ENGINE=InnoDB AUTO_INCREMENT=59202 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.email_subscriptions
CREATE TABLE IF NOT EXISTS `email_subscriptions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) DEFAULT NULL,
  `scope` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `subscribed` tinyint(1) DEFAULT NULL,
  `recipient_type` varchar(255) DEFAULT NULL,
  `recipient_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_unsubscribes_on_email` (`email`),
  KEY `index_unsubscribes_on_scope` (`scope`)
) ENGINE=InnoDB AUTO_INCREMENT=77520 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.eolcnames
CREATE TABLE IF NOT EXISTS `eolcnames` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `eolsname_id` int(11) DEFAULT NULL,
  `cname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `language` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `eol_preferred` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_eolcnames_on_eolsname_id` (`eolsname_id`)
) ENGINE=InnoDB AUTO_INCREMENT=657369 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.eolsnames
CREATE TABLE IF NOT EXISTS `eolsnames` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `taxon` text COLLATE utf8_unicode_ci,
  `data` longtext COLLATE utf8_unicode_ci,
  `picture` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `gbif_id` int(11) DEFAULT NULL,
  `worms_id` int(11) DEFAULT NULL,
  `fishbase_id` int(11) DEFAULT NULL,
  `worms_parent_id` int(11) DEFAULT NULL,
  `fishbase_parent_id` int(11) DEFAULT NULL,
  `worms_taxonrank` enum('life','domain','kingdom','phylum','class','order','family','genus','species') COLLATE utf8_unicode_ci DEFAULT NULL,
  `fishbase_taxonrank` enum('life','domain','kingdom','phylum','class','order','family','genus','species') COLLATE utf8_unicode_ci DEFAULT NULL,
  `worms_hierarchy` text COLLATE utf8_unicode_ci,
  `fishbase_hierarchy` text COLLATE utf8_unicode_ci,
  `category` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `taxonrank` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `parent_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `has_occurences` tinyint(1) DEFAULT '0',
  `eol_description` longtext COLLATE utf8_unicode_ci,
  `thumbnail_href` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `category_inspire` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_eolsnames_2_on_gbif_id` (`gbif_id`),
  KEY `index_eolsnames_2_on_worms_id` (`worms_id`),
  KEY `index_eolsnames_2_on_fishbase_id` (`fishbase_id`),
  KEY `index_eolsnames_2_on_worms_parent_id` (`worms_parent_id`),
  KEY `index_eolsnames_2_on_fishbase_parent_id` (`fishbase_parent_id`),
  KEY `index_eolsnames_2_on_worms_taxonrank` (`worms_taxonrank`),
  KEY `index_eolsnames_2_on_fishbase_taxonrank` (`fishbase_taxonrank`),
  KEY `index_eolsnames_2_on_category` (`category`),
  KEY `index_eolsnames_on_taxonrank` (`taxonrank`),
  KEY `index_eolsnames_on_parent_id` (`parent_id`)
) ENGINE=InnoDB AUTO_INCREMENT=46476720 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.external_users
CREATE TABLE IF NOT EXISTS `external_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fb_id` bigint(20) DEFAULT NULL,
  `nickname` text COLLATE utf8_unicode_ci,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `picturl` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_external_users_on_email` (`email`),
  KEY `index_external_users_on_fb_id` (`fb_id`)
) ENGINE=InnoDB AUTO_INCREMENT=26156 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.fb_comments
CREATE TABLE IF NOT EXISTS `fb_comments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source_type` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `source_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `raw_data` longtext CHARACTER SET latin1,
  PRIMARY KEY (`id`),
  KEY `index_fb_comments_on_source_type` (`source_type`),
  KEY `index_fb_comments_on_source_id` (`source_id`)
) ENGINE=InnoDB AUTO_INCREMENT=115566 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.fb_likes
CREATE TABLE IF NOT EXISTS `fb_likes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source_type` varchar(255) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  `source_id` int(11) NOT NULL,
  `url` varchar(255) CHARACTER SET latin1 COLLATE latin1_bin NOT NULL DEFAULT '',
  `click_count` int(11) DEFAULT NULL,
  `comment_count` int(11) DEFAULT NULL,
  `comments_fbid` int(11) DEFAULT NULL,
  `commentsbox_count` int(11) DEFAULT NULL,
  `like_count` int(11) DEFAULT NULL,
  `share_count` int(11) DEFAULT NULL,
  `total_count` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_fb_likes_on_url` (`url`),
  KEY `source_type` (`source_type`,`source_id`),
  KEY `index_fb_likes_on_source_type_and_source_id` (`source_type`,`source_id`)
) ENGINE=InnoDB AUTO_INCREMENT=164223 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.fish_frequencies
CREATE TABLE IF NOT EXISTS `fish_frequencies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `gbif_id` int(11) NOT NULL,
  `lat` int(11) NOT NULL,
  `lng` int(11) NOT NULL,
  `count` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_fish_frequencies_on_gbif_id` (`gbif_id`),
  KEY `index_fish_frequencies_on_lat_and_lng_and_count` (`lat`,`lng`,`count`)
) ENGINE=InnoDB AUTO_INCREMENT=8246119 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.gbif_ipts
CREATE TABLE IF NOT EXISTS `gbif_ipts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dive_id` int(11) DEFAULT NULL,
  `eol_id` int(11) DEFAULT NULL,
  `g_modified` varchar(255) DEFAULT NULL,
  `g_institutionCode` varchar(255) DEFAULT NULL,
  `g_references` varchar(255) DEFAULT NULL,
  `g_catalognumber` varchar(255) DEFAULT NULL,
  `g_scientificnName` varchar(255) DEFAULT NULL,
  `g_basisOfRecord` varchar(255) DEFAULT NULL,
  `g_nameAccordingTo` varchar(255) DEFAULT NULL,
  `g_dateIdentified` varchar(255) DEFAULT NULL,
  `g_bibliographicCitation` varchar(255) DEFAULT NULL,
  `g_kingdom` varchar(255) DEFAULT NULL,
  `g_phylum` varchar(255) DEFAULT NULL,
  `g_class` varchar(255) DEFAULT NULL,
  `g_order` varchar(255) DEFAULT NULL,
  `g_family` varchar(255) DEFAULT NULL,
  `g_genus` varchar(255) DEFAULT NULL,
  `g_specificEpithet` varchar(255) DEFAULT NULL,
  `g_infraspecificEpitet` varchar(255) DEFAULT NULL,
  `g_scientificNameAuthorship` varchar(255) DEFAULT NULL,
  `g_identifiedBy` varchar(255) DEFAULT NULL,
  `g_recordedBy` varchar(255) DEFAULT NULL,
  `g_eventDate` varchar(255) DEFAULT NULL,
  `g_eventTime` varchar(255) DEFAULT NULL,
  `g_higherGeographyID` varchar(255) DEFAULT NULL,
  `g_country` varchar(255) DEFAULT NULL,
  `g_locality` varchar(255) DEFAULT NULL,
  `g_decimalLongitude` varchar(255) DEFAULT NULL,
  `g_decimallatitude` varchar(255) DEFAULT NULL,
  `g_CoordinatePrecision` varchar(255) DEFAULT NULL,
  `g_MinimumDepth` varchar(255) DEFAULT NULL,
  `g_MaximumDepth` varchar(255) DEFAULT NULL,
  `g_Temperature` varchar(255) DEFAULT NULL,
  `g_Continent` varchar(255) DEFAULT NULL,
  `g_waterBody` varchar(255) DEFAULT NULL,
  `g_eventRemarks` varchar(255) DEFAULT NULL,
  `g_fieldnotes` varchar(255) DEFAULT NULL,
  `g_locationRemarks` varchar(255) DEFAULT NULL,
  `g_type` varchar(255) DEFAULT NULL,
  `g_language` varchar(255) DEFAULT NULL,
  `g_rights` varchar(255) DEFAULT NULL,
  `g_rightsholder` varchar(255) DEFAULT NULL,
  `g_datasetID` varchar(255) DEFAULT NULL,
  `g_datasetName` varchar(255) DEFAULT NULL,
  `g_ownerintitutionCode` varchar(255) DEFAULT NULL,
  `g_countryCode` varchar(255) DEFAULT NULL,
  `g_geodeticDatim` varchar(255) DEFAULT NULL,
  `g_georeferenceSources` varchar(255) DEFAULT NULL,
  `g_minimumElevationInMeters` varchar(255) DEFAULT NULL,
  `g_maximumElevationInMeters` varchar(255) DEFAULT NULL,
  `g_taxonID` varchar(255) DEFAULT NULL,
  `g_nameAccordingToID` varchar(255) DEFAULT NULL,
  `g_taxonRankvernacularName` varchar(255) DEFAULT NULL,
  `g_occurrenceID` varchar(255) DEFAULT NULL,
  `g_associatedMedia` varchar(255) DEFAULT NULL,
  `g_eventID` varchar(255) DEFAULT NULL,
  `g_habitat` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_gbif_ipts_on_dive_id` (`dive_id`),
  KEY `index_gbif_ipts_on_eol_id` (`eol_id`)
) ENGINE=InnoDB AUTO_INCREMENT=76060 DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.geonames_alternate_names
CREATE TABLE IF NOT EXISTS `geonames_alternate_names` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `geoname_id` int(11) DEFAULT NULL,
  `language` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  `preferred` tinyint(1) DEFAULT NULL,
  `short_name` tinyint(1) DEFAULT NULL,
  `colloquial` tinyint(1) DEFAULT NULL,
  `historic` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_geonames_alternate_names_stage_utf8_on_name` (`name`),
  KEY `index_geoname_id` (`geoname_id`,`language`,`preferred`)
) ENGINE=InnoDB AUTO_INCREMENT=8552004 DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.geonames_cores
CREATE TABLE IF NOT EXISTS `geonames_cores` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(200) COLLATE utf8_unicode_ci DEFAULT NULL,
  `asciiname` varchar(200) COLLATE utf8_unicode_ci DEFAULT NULL,
  `alternatenames` varchar(5000) COLLATE utf8_unicode_ci DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `feature_class` varchar(1) COLLATE utf8_unicode_ci DEFAULT NULL,
  `feature_code` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country_code` varchar(5) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cc2` varchar(60) COLLATE utf8_unicode_ci DEFAULT NULL,
  `admin1_code` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `admin2_code` varchar(80) COLLATE utf8_unicode_ci DEFAULT NULL,
  `admin3_code` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `admin4_code` varchar(20) COLLATE utf8_unicode_ci DEFAULT NULL,
  `population` bigint(20) unsigned DEFAULT NULL,
  `elevation` int(11) DEFAULT NULL,
  `gtopo30` int(11) DEFAULT NULL,
  `timezone_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `updated_at` date DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `hierarchy_adm` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_geonames_cores_on_feature_class` (`feature_class`),
  KEY `index_geonames_cores_on_latitude_and_longitude` (`latitude`,`longitude`),
  KEY `index_geonames_cores_on_feature_code` (`feature_code`),
  KEY `index_geonames_cores_on_country_code` (`country_code`),
  KEY `index_geonames_cores_on_parent_id` (`parent_id`),
  KEY `index_geonames_cores_on_name_and_country_code` (`name`,`country_code`),
  KEY `index_geonames_cores_on_asciiname_and_country_code` (`asciiname`,`country_code`),
  KEY `index_geonames_cores_on_latitude` (`latitude`),
  KEY `index_geonames_cores_on_longitude` (`longitude`)
) ENGINE=InnoDB AUTO_INCREMENT=8015400 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.geonames_countries
CREATE TABLE IF NOT EXISTS `geonames_countries` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `ISO` varchar(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ISO3` varchar(3) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ISONumeric` varchar(3) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `capital` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `area` int(11) DEFAULT NULL,
  `population` int(11) DEFAULT NULL,
  `continent` varchar(2) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tld` varchar(4) COLLATE utf8_unicode_ci DEFAULT NULL,
  `currency_code` varchar(3) COLLATE utf8_unicode_ci DEFAULT NULL,
  `currency_name` varchar(30) COLLATE utf8_unicode_ci DEFAULT NULL,
  `currency_symbol` varchar(6) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `postcode` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `postcode_regexp` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `languages` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `geonames_id` int(11) DEFAULT NULL,
  `neighbours` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `depends_from` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `feature_code` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_geonames_countries_on_ISO` (`ISO`),
  KEY `index_geonames_countries_on_ISO3` (`ISO3`),
  KEY `index_geonames_countries_on_continent` (`continent`),
  KEY `index_geonames_countries_on_geonames_id` (`geonames_id`)
) ENGINE=InnoDB AUTO_INCREMENT=253 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.geonames_featurecodes
CREATE TABLE IF NOT EXISTS `geonames_featurecodes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `feature_code` varchar(10) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_geonames_featurecodes_on_feature_code` (`feature_code`)
) ENGINE=InnoDB AUTO_INCREMENT=658 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.goods_to_sell
CREATE TABLE IF NOT EXISTS `goods_to_sell` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `shop_id` int(11) NOT NULL,
  `realm` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `cat1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cat2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cat3` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `title` text COLLATE utf8_unicode_ci NOT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `picture_id` int(11) DEFAULT NULL,
  `stock_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `stock_id` int(11) DEFAULT NULL,
  `price_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `price` float DEFAULT NULL,
  `tax` float DEFAULT NULL,
  `total` float DEFAULT NULL,
  `currency` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `order_num` int(11) NOT NULL DEFAULT '-1',
  `status` enum('public','deleted') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'public',
  `deposit` float DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `goods_to_sell_on_shop_id` (`shop_id`,`realm`,`status`,`order_num`)
) ENGINE=InnoDB AUTO_INCREMENT=14037 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.i18n_languages
CREATE TABLE IF NOT EXISTS `i18n_languages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `code3` varchar(255) DEFAULT NULL,
  `code2` varchar(255) DEFAULT NULL,
  `lang` varchar(255) DEFAULT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_i18n_languages_on_code3_and_lang` (`code3`,`lang`),
  KEY `index_i18n_languages_on_code2_and_lang` (`code2`,`lang`)
) ENGINE=InnoDB AUTO_INCREMENT=971 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.internal_messages
CREATE TABLE IF NOT EXISTS `internal_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `from_id` int(11) DEFAULT NULL,
  `from_group_id` int(11) DEFAULT NULL,
  `to_id` int(11) DEFAULT NULL,
  `topic` varchar(255) DEFAULT NULL,
  `message` text,
  `in_reply_to_type` varchar(255) DEFAULT NULL,
  `in_reply_to_id` int(11) DEFAULT NULL,
  `basket_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `status` varchar(255) NOT NULL DEFAULT 'new',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=58 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.locations
CREATE TABLE IF NOT EXISTS `locations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `nesw_bounds` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `verified_user_id` int(11) DEFAULT NULL,
  `verified_date` datetime DEFAULT NULL,
  `redirect_id` int(11) DEFAULT NULL,
  `best_pic_ids` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `delta` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `index_locations_on_country_id` (`country_id`),
  KEY `index_locations_on_name` (`name`),
  KEY `index_locations_on_delta` (`delta`)
) ENGINE=InnoDB AUTO_INCREMENT=84004 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.locations_regions
CREATE TABLE IF NOT EXISTS `locations_regions` (
  `location_id` int(11) DEFAULT NULL,
  `region_id` int(11) DEFAULT NULL,
  KEY `index_locations_regions_on_location_id_and_region_id` (`location_id`,`region_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.memberships
CREATE TABLE IF NOT EXISTS `memberships` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  `role` enum('admin','member') COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_memberships_on_user_id_and_role` (`user_id`,`role`),
  KEY `index_memberships_on_group_id_and_role` (`group_id`,`role`)
) ENGINE=InnoDB AUTO_INCREMENT=788 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.mod_histories
CREATE TABLE IF NOT EXISTS `mod_histories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `obj_id` int(11) DEFAULT NULL,
  `table` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `operation` int(11) DEFAULT NULL,
  `before` text COLLATE utf8_unicode_ci,
  `after` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=29889 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.newsletters
CREATE TABLE IF NOT EXISTS `newsletters` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `html_content` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `distributed_at` datetime DEFAULT NULL,
  `reports` text COLLATE utf8_unicode_ci,
  `sending_pid` int(11) DEFAULT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.newsletter_users
CREATE TABLE IF NOT EXISTS `newsletter_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `newsletter_id` int(11) DEFAULT NULL,
  `recipient_id` int(11) DEFAULT NULL,
  `recipient_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=206476 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.notifications
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `kind` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `dismissed_at` datetime DEFAULT NULL,
  `about_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `about_id` int(11) NOT NULL,
  `param` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `index_notifications_on_user_id_and_created_at` (`user_id`,`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=42063 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.payments
CREATE TABLE IF NOT EXISTS `payments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `category` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `subscription_plan_id` int(11) DEFAULT NULL,
  `status` enum('pending','confirmed','cancelled','refunded') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'pending',
  `confirmation_date` date DEFAULT NULL,
  `cancellation_date` date DEFAULT NULL,
  `refund_date` date DEFAULT NULL,
  `validity_date` date DEFAULT NULL,
  `amount` float NOT NULL,
  `recurring` tinyint(1) NOT NULL DEFAULT '0',
  `ref_paypal` text COLLATE utf8_unicode_ci,
  `comment` text COLLATE utf8_unicode_ci,
  `storage_duration` bigint(20) DEFAULT NULL,
  `storage_limit` bigint(20) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `rec_profile_paypal` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `shop_id` int(11) DEFAULT NULL,
  `donation` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_payments_on_user_id_and_status` (`user_id`,`status`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.pictures
CREATE TABLE IF NOT EXISTS `pictures` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `href` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `cache` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `notes` text COLLATE utf8_unicode_ci,
  `small_id` int(11) DEFAULT NULL,
  `medium_id` int(11) DEFAULT NULL,
  `size` int(11) NOT NULL DEFAULT '0',
  `media` enum('image','video') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'image',
  `webm` int(11) DEFAULT NULL,
  `mp4` int(11) DEFAULT NULL,
  `exif` longtext COLLATE utf8_unicode_ci,
  `thumb_id` int(11) DEFAULT NULL,
  `large_id` int(11) DEFAULT NULL,
  `large_fb_id` int(11) DEFAULT NULL,
  `original_image_path` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `original_video_path` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `original_image_id` int(11) DEFAULT NULL,
  `original_video_id` int(11) DEFAULT NULL,
  `great_pic` tinyint(1) DEFAULT NULL,
  `width` int(11) DEFAULT NULL,
  `height` int(11) DEFAULT NULL,
  `original_content_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fb_graph_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_pictures_on_dive_id_and_updated_at` (`updated_at`),
  KEY `index_pictures_on_updated_at` (`updated_at`),
  KEY `index_pictures_on_user_id` (`user_id`),
  KEY `index_pictures_on_small_id` (`small_id`),
  KEY `index_pictures_on_thumb_id` (`thumb_id`),
  KEY `index_pictures_on_medium_id` (`medium_id`),
  KEY `index_pictures_on_large_id` (`large_id`),
  KEY `index_pictures_on_original_image_id` (`original_image_id`),
  KEY `index_pictures_on_original_video_id` (`original_video_id`),
  KEY `index_pictures_on_webm` (`webm`),
  KEY `index_pictures_on_mp4` (`mp4`)
) ENGINE=InnoDB AUTO_INCREMENT=108361 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.pictures_eolcnames
CREATE TABLE IF NOT EXISTS `pictures_eolcnames` (
  `picture_id` int(11) DEFAULT NULL,
  `sname_id` int(11) DEFAULT NULL,
  `cname_id` int(11) DEFAULT NULL,
  KEY `index_pictures_eolcnames_on_picture_id` (`picture_id`),
  KEY `index_pictures_eolcnames_on_sname_id` (`sname_id`),
  KEY `index_pictures_eolcnames_on_cname_id` (`cname_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.picture_album_pictures
CREATE TABLE IF NOT EXISTS `picture_album_pictures` (
  `picture_album_id` int(11) NOT NULL,
  `picture_id` int(11) NOT NULL,
  `ordnum` int(11) NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`picture_album_id`,`ordnum`),
  KEY `index_picture_album_pictures_on_picture_id` (`picture_id`),
  KEY `picture_album_pictures_on_album` (`picture_album_id`,`ordnum`,`picture_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.profile_data
CREATE TABLE IF NOT EXISTS `profile_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dive_id` int(11) NOT NULL,
  `seconds` int(11) NOT NULL,
  `depth` float DEFAULT NULL,
  `current_water_temperature` float DEFAULT NULL,
  `main_cylinder_pressure` float DEFAULT NULL,
  `heart_beats` float DEFAULT NULL,
  `deco_violation` tinyint(1) NOT NULL DEFAULT '0',
  `deco_start` tinyint(1) NOT NULL DEFAULT '0',
  `ascent_violation` tinyint(1) NOT NULL DEFAULT '0',
  `bookmark` tinyint(1) NOT NULL DEFAULT '0',
  `surface_event` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `index_profile_data_on_dive_id_and_seconds` (`dive_id`,`seconds`)
) ENGINE=InnoDB AUTO_INCREMENT=64246183 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.regions
CREATE TABLE IF NOT EXISTS `regions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `nesw_bounds` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `verified_user_id` int(11) DEFAULT NULL,
  `verified_date` datetime DEFAULT NULL,
  `redirect_id` int(11) DEFAULT NULL,
  `best_pic_ids` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `delta` tinyint(1) NOT NULL DEFAULT '1',
  `geonames_core_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_regions_on_name` (`name`),
  KEY `index_regions_on_delta` (`delta`)
) ENGINE=InnoDB AUTO_INCREMENT=4474 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.reviews
CREATE TABLE IF NOT EXISTS `reviews` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `shop_id` int(11) NOT NULL,
  `anonymous` tinyint(1) NOT NULL DEFAULT '0',
  `recommend` tinyint(1) NOT NULL,
  `mark_orga` int(11) DEFAULT NULL,
  `mark_friend` int(11) DEFAULT NULL,
  `mark_secu` int(11) DEFAULT NULL,
  `mark_boat` int(11) DEFAULT NULL,
  `mark_rent` int(11) DEFAULT NULL,
  `title` text COLLATE utf8_unicode_ci,
  `comment` text COLLATE utf8_unicode_ci,
  `service` enum('autonomous','guide','training','snorkeling','fill','other') COLLATE utf8_unicode_ci NOT NULL,
  `spam` tinyint(1) NOT NULL DEFAULT '0',
  `reported_spam` tinyint(1) NOT NULL DEFAULT '0',
  `flag_moderate` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `reply` text COLLATE utf8_unicode_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_reviews_on_user_id_and_shop_id` (`user_id`,`shop_id`),
  KEY `index_reviews_on_shop_id_and_created_at` (`shop_id`,`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=1518 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.review_votes
CREATE TABLE IF NOT EXISTS `review_votes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `review_id` int(11) NOT NULL,
  `vote` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_review_votes_on_review_id_and_vote` (`review_id`,`vote`),
  KEY `index_review_votes_on_user_id_and_review_id` (`user_id`,`review_id`)
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.schema_migrations
CREATE TABLE IF NOT EXISTS `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.seo_logs
CREATE TABLE IF NOT EXISTS `seo_logs` (
  `lookup` varchar(255) DEFAULT NULL,
  `date` datetime DEFAULT NULL,
  `idx` int(11) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `other` text,
  KEY `index_seo_logs_on_lookup` (`lookup`),
  KEY `index_seo_logs_on_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.sessions
CREATE TABLE IF NOT EXISTS `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `data` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB AUTO_INCREMENT=157873074 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.shops
CREATE TABLE IF NOT EXISTS `shops` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `source_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `kind` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `lat` float DEFAULT NULL,
  `lng` float DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `address` text COLLATE utf8_unicode_ci,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `web` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `phone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `desc` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `moderate` tinyint(1) NOT NULL DEFAULT '0',
  `shop_vanity` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `category` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `about_html` text COLLATE utf8_unicode_ci,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `country_code` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `facebook` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `twitter` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `google_plus` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `openings` text COLLATE utf8_unicode_ci,
  `nearby` text COLLATE utf8_unicode_ci,
  `private_user_id` int(11) DEFAULT NULL,
  `flag_moderate_private_to_public` tinyint(1) DEFAULT NULL,
  `google_geocode` text COLLATE utf8_unicode_ci,
  `realm_dive` tinyint(1) DEFAULT NULL,
  `realm_home` tinyint(1) DEFAULT NULL,
  `realm_gear` tinyint(1) DEFAULT NULL,
  `realm_travel` tinyint(1) DEFAULT NULL,
  `paypal_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `paypal_token` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `paypal_secret` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `score` int(11) NOT NULL DEFAULT '-1',
  `delta` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `index_shops_on_delta` (`delta`)
) ENGINE=InnoDB AUTO_INCREMENT=11077 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for view diveboard.shops_shared
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE IF NOT EXISTS `shops_shared` (
	`id` INT(11) NOT NULL,
	`kind` VARCHAR(255) NULL COLLATE 'utf8_unicode_ci',
	`lat` FLOAT NULL,
	`lng` FLOAT NULL,
	`name` VARCHAR(255) NULL COLLATE 'utf8_unicode_ci',
	`moderate` TINYINT(1) NOT NULL,
	`category` VARCHAR(255) NULL COLLATE 'utf8_unicode_ci',
	`city` VARCHAR(255) NULL COLLATE 'utf8_unicode_ci',
	`country_code` VARCHAR(255) NULL COLLATE 'utf8_unicode_ci'
) ENGINE=MyISAM;

-- Dumping structure for view diveboard.shop_customers
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE IF NOT EXISTS `shop_customers` (
	`id` BIGINT(28) NULL,
	`shop_id` INT(11) NULL,
	`user_id` BIGINT(20) NULL,
	`dive_count` BIGINT(21) NOT NULL,
	`review_id` INT(11) NULL,
	`basket_count` BIGINT(21) NOT NULL,
	`message_to_count` BIGINT(21) NOT NULL,
	`message_from_count` BIGINT(21) NOT NULL
) ENGINE=MyISAM;

-- Dumping structure for view diveboard.shop_customer_detail
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE IF NOT EXISTS `shop_customer_detail` (
	`shop_id` INT(11) NULL,
	`user_id` BIGINT(20) NULL,
	`stuff_type` VARCHAR(15) NOT NULL COLLATE 'utf8_general_ci',
	`registered_at` DATETIME NULL,
	`dive_id` INT(11) NULL,
	`review_id` INT(11) NULL,
	`basket_id` INT(11) NULL,
	`message_id_from` INT(11) NULL,
	`message_id_to` INT(11) NULL
) ENGINE=MyISAM;

-- Dumping structure for view diveboard.shop_customer_history
-- Creating temporary table to overcome VIEW dependency errors
CREATE TABLE IF NOT EXISTS `shop_customer_history` (
	`shop_id` INT(11) NULL,
	`user_id` BIGINT(20) NULL,
	`registered_at` DATETIME NULL,
	`stuff_type` VARCHAR(15) NOT NULL COLLATE 'utf8_general_ci',
	`stuff_id` BIGINT(11) NULL
) ENGINE=MyISAM;

-- Dumping structure for table diveboard.shop_densities
CREATE TABLE IF NOT EXISTS `shop_densities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `minLat` float DEFAULT NULL,
  `minLng` float DEFAULT NULL,
  `maxLat` float DEFAULT NULL,
  `maxLng` float DEFAULT NULL,
  `shop_density` int(11) DEFAULT NULL,
  `dive_density` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3417 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.shop_details
CREATE TABLE IF NOT EXISTS `shop_details` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `kind` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `value` varchar(4096) CHARACTER SET latin1 DEFAULT NULL,
  `shop_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_shop_details_on_shop_id_and_kind` (`shop_id`,`kind`)
) ENGINE=InnoDB AUTO_INCREMENT=20054 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.shop_q_and_as
CREATE TABLE IF NOT EXISTS `shop_q_and_as` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `shop_id` int(11) DEFAULT NULL,
  `question` varchar(255) DEFAULT NULL,
  `answer` varchar(255) DEFAULT NULL,
  `language` varchar(3) DEFAULT NULL,
  `official` tinyint(1) DEFAULT '0',
  `position` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=992393 DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.shop_widgets
CREATE TABLE IF NOT EXISTS `shop_widgets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `shop_id` int(11) DEFAULT NULL,
  `widget_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `widget_id` int(11) NOT NULL,
  `realm` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `set` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `column` int(11) NOT NULL DEFAULT '0',
  `position` int(11) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_shop_widgets_on_shop_id_and_set_and_realm_and_position` (`shop_id`,`set`,`realm`,`position`)
) ENGINE=InnoDB AUTO_INCREMENT=22154 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.signatures
CREATE TABLE IF NOT EXISTS `signatures` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dive_id` int(11) DEFAULT NULL,
  `signby_type` varchar(255) DEFAULT NULL,
  `signby_id` int(11) DEFAULT NULL,
  `signed_data` text,
  `request_date` datetime DEFAULT NULL,
  `signed_date` datetime DEFAULT NULL,
  `rejected` tinyint(1) DEFAULT '0',
  `notified_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `signby_type` (`signby_type`,`signby_id`),
  KEY `index_signatures_on_dive_id` (`dive_id`)
) ENGINE=InnoDB AUTO_INCREMENT=43413 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.spots
CREATE TABLE IF NOT EXISTS `spots` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `lat` float NOT NULL DEFAULT '0',
  `long` float NOT NULL DEFAULT '0',
  `zoom` int(11) NOT NULL DEFAULT '7',
  `moderate_id` int(11) DEFAULT NULL,
  `precise` tinyint(1) NOT NULL DEFAULT '0',
  `description` text COLLATE utf8_unicode_ci,
  `map` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `location_id` int(11) NOT NULL DEFAULT '1',
  `region_id` int(11) DEFAULT NULL,
  `country_id` int(11) NOT NULL DEFAULT '1',
  `private_user_id` int(11) DEFAULT NULL,
  `flag_moderate_private_to_public` tinyint(1) DEFAULT NULL,
  `verified_user_id` int(11) DEFAULT NULL,
  `verified_date` datetime DEFAULT NULL,
  `redirect_id` int(11) DEFAULT NULL,
  `from_bulk` tinyint(1) DEFAULT '0',
  `within_country_bounds` tinyint(1) DEFAULT NULL,
  `best_pic_ids` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `score` int(11) DEFAULT NULL,
  `delta` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  KEY `index_spots_on_lat_and_long` (`lat`,`long`),
  KEY `index_spots_on_location_id` (`location_id`),
  KEY `index_spots_on_region_id` (`region_id`),
  KEY `index_spots_on_country_id` (`country_id`),
  KEY `index_spots_on_delta` (`delta`)
) ENGINE=InnoDB AUTO_INCREMENT=168108 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.spot_compare
CREATE TABLE IF NOT EXISTS `spot_compare` (
  `a_id` int(11) NOT NULL DEFAULT '0',
  `b_id` int(11) NOT NULL DEFAULT '0',
  `dl_dst` int(3) NOT NULL DEFAULT '0',
  `1_dst` double DEFAULT NULL,
  `untrusted_coord` int(1) NOT NULL DEFAULT '0',
  `included` int(0) DEFAULT NULL,
  `country_included` int(0) DEFAULT NULL,
  `same_country` int(0) DEFAULT NULL,
  `same_region` int(0) DEFAULT NULL,
  `same_location` int(0) DEFAULT NULL,
  `match_class` varchar(255) DEFAULT NULL,
  `cluster_id` int(11) DEFAULT NULL,
  KEY `spot_compare_idx1` (`a_id`,`match_class`,`b_id`),
  KEY `spot_compare_idx2` (`b_id`,`match_class`,`a_id`),
  KEY `spot_compare_idx3` (`cluster_id`,`match_class`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.spot_compare_tmp
CREATE TABLE IF NOT EXISTS `spot_compare_tmp` (
  `a_id` int(11) NOT NULL DEFAULT '0',
  `b_id` int(11) NOT NULL DEFAULT '0',
  `dl_dst` int(3) NOT NULL DEFAULT '0',
  `1_dst` double DEFAULT NULL,
  `untrusted_coord` int(1) NOT NULL DEFAULT '0',
  `included` int(11) DEFAULT NULL,
  `country_included` int(11) DEFAULT NULL,
  `same_country` int(11) DEFAULT NULL,
  `same_region` int(11) DEFAULT NULL,
  `same_location` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.spot_moderations
CREATE TABLE IF NOT EXISTS `spot_moderations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `a_id` int(11) DEFAULT NULL,
  `b_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_spot_moderations_on_a_id_and_b_id` (`a_id`,`b_id`),
  KEY `index_spot_moderations_on_b_id_and_a_id` (`b_id`,`a_id`)
) ENGINE=InnoDB AUTO_INCREMENT=364 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.stats_logs
CREATE TABLE IF NOT EXISTS `stats_logs` (
  `time` datetime DEFAULT NULL,
  `sub_count` int(11) DEFAULT NULL,
  `ip` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `method` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `params` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `ref` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_agent` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL
) ENGINE=ARCHIVE DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.stats_sums
CREATE TABLE IF NOT EXISTS `stats_sums` (
  `aggreg` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `time` datetime DEFAULT NULL,
  `col1` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `col2` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `nb` int(11) DEFAULT NULL,
  KEY `index_stats_sums_on_aggreg_and_time_and_col1_and_col2` (`aggreg`,`time`,`col1`,`col2`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.subscription_plans
CREATE TABLE IF NOT EXISTS `subscription_plans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `category` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `title` varchar(255) NOT NULL,
  `option_name` varchar(255) DEFAULT '1',
  `option_title` varchar(255) DEFAULT '1',
  `period` int(11) NOT NULL DEFAULT '1',
  `available` tinyint(1) NOT NULL DEFAULT '1',
  `preferred` tinyint(1) NOT NULL DEFAULT '0',
  `price` float DEFAULT NULL,
  `commercial_note` text,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.tags
CREATE TABLE IF NOT EXISTS `tags` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(255) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=561 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.tanks
CREATE TABLE IF NOT EXISTS `tanks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `p_start` float DEFAULT NULL,
  `p_end` float DEFAULT NULL,
  `time_start` int(11) DEFAULT NULL,
  `o2` int(11) DEFAULT NULL,
  `n2` int(11) DEFAULT NULL,
  `he` int(11) DEFAULT NULL,
  `volume` float DEFAULT NULL,
  `dive_id` int(11) DEFAULT NULL,
  `order` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `material` enum('aluminium','steel','carbon') COLLATE utf8_unicode_ci DEFAULT NULL,
  `multitank` int(11) NOT NULL DEFAULT '1',
  `p_start_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `p_start_value` float DEFAULT NULL,
  `p_end_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `p_end_value` float DEFAULT NULL,
  `volume_unit` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `volume_value` float DEFAULT NULL,
  `gas_type` enum('air','nitrox','trimix') COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_tanks_on_dive_id_and_order` (`dive_id`,`order`)
) ENGINE=InnoDB AUTO_INCREMENT=208376 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.treasures
CREATE TABLE IF NOT EXISTS `treasures` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `object_type` varchar(255) DEFAULT NULL,
  `object_id` int(11) DEFAULT NULL,
  `campaign_name` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=73 DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.trips
CREATE TABLE IF NOT EXISTS `trips` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `album_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_trips_on_album_id` (`album_id`),
  KEY `index_trips_on_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=27773 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.uploaded_profiles
CREATE TABLE IF NOT EXISTS `uploaded_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source` text COLLATE utf8_unicode_ci NOT NULL,
  `data` longblob NOT NULL,
  `log` text COLLATE utf8_unicode_ci,
  `source_detail` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `agent` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_uploaded_profiles_on_user_id_and_created_at` (`user_id`,`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=24524 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.users
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fb_id` bigint(20) DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `vanity_url` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `nickname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `location` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `settings` text COLLATE utf8_unicode_ci,
  `pict` tinyint(1) DEFAULT NULL,
  `admin_rights` int(11) NOT NULL DEFAULT '0',
  `fbtoken` text COLLATE utf8_unicode_ci,
  `password` text COLLATE utf8_unicode_ci,
  `contact_email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fb_permissions` text COLLATE utf8_unicode_ci,
  `about` text COLLATE utf8_unicode_ci,
  `total_ext_dives` int(11) NOT NULL DEFAULT '0',
  `plugin_debug` enum('DEBUG','INFO','ERROR') COLLATE utf8_unicode_ci DEFAULT NULL,
  `dan_data` longtext COLLATE utf8_unicode_ci,
  `quota_type` enum('per_dive','per_user','per_month') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'per_month',
  `quota_limit` bigint(20) NOT NULL DEFAULT '524288000',
  `quota_expire` date DEFAULT NULL,
  `shop_proxy_id` int(11) DEFAULT NULL,
  `city` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `lat` float DEFAULT NULL,
  `lng` float DEFAULT NULL,
  `skip_import_dives` mediumtext COLLATE utf8_unicode_ci,
  `currency` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `delta` tinyint(1) NOT NULL DEFAULT '1',
  `source` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `preferred_locale` varchar(255) COLLATE utf8_unicode_ci DEFAULT 'en',
  `movescount_email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `movescount_userkey` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_users_on_vanity_url` (`vanity_url`),
  KEY `index_users_on_fb_id` (`fb_id`),
  KEY `index_users_on_shop_proxy_id` (`shop_proxy_id`),
  KEY `index_users_on_lat_and_lng` (`lat`,`lng`),
  KEY `index_users_on_email` (`email`),
  KEY `contact_email` (`contact_email`),
  KEY `index_users_on_delta` (`delta`)
) ENGINE=InnoDB AUTO_INCREMENT=45978 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.users_buddies
CREATE TABLE IF NOT EXISTS `users_buddies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `buddy_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `buddy_id` int(11) NOT NULL,
  `invited_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_users_buddies_on_user_id` (`user_id`),
  KEY `index_users_buddies_on_buddy_id_and_buddy_type` (`buddy_id`,`buddy_type`)
) ENGINE=InnoDB AUTO_INCREMENT=147586 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.user_extra_activities
CREATE TABLE IF NOT EXISTS `user_extra_activities` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `geoname_id` int(11) DEFAULT NULL,
  `lat` float DEFAULT NULL,
  `lng` float DEFAULT NULL,
  `year` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.user_gears
CREATE TABLE IF NOT EXISTS `user_gears` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `manufacturer` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `model` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `acquisition` date DEFAULT NULL,
  `last_revision` date DEFAULT NULL,
  `reference` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `category` enum('BCD','Boots','Computer','Compass','Camera','Cylinder','Dry suit','Dive skin','Fins','Gloves','Hood','Knife','Light','Lift bag','Mask','Other','Rebreather','Regulator','Scooter','Wet suit') COLLATE utf8_unicode_ci NOT NULL,
  `auto_feature` enum('never','featured','other') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'never',
  `pref_order` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_user_gears_on_user_id` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=12920 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.widget_list_dives
CREATE TABLE IF NOT EXISTS `widget_list_dives` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_id` int(11) DEFAULT NULL,
  `from_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `from_id` int(11) NOT NULL,
  `limit` int(11) NOT NULL DEFAULT '10',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.widget_picture_banners
CREATE TABLE IF NOT EXISTS `widget_picture_banners` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `album_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9628 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.widget_texts
CREATE TABLE IF NOT EXISTS `widget_texts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `content` text COLLATE utf8_unicode_ci,
  `read_only` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9645 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.wikis
CREATE TABLE IF NOT EXISTS `wikis` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `source_id` int(11) DEFAULT NULL,
  `source_type` enum('Spot','Country','Location','Region','BlogPost') COLLATE utf8_unicode_ci DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `verified_user_id` int(11) DEFAULT NULL,
  `data` longtext COLLATE utf8_unicode_ci,
  `album_id` int(11) DEFAULT NULL,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_wikis_on_object_id` (`source_id`),
  KEY `index_wikis_on_object_type` (`source_type`),
  KEY `index_wikis_on_user_id` (`user_id`),
  KEY `index_wikis_on_album_id` (`album_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2200 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

-- Data exporting was unselected.
-- Dumping structure for table diveboard.ZZ_users_fb_data
CREATE TABLE IF NOT EXISTS `ZZ_users_fb_data` (
  `user_id` int(11) unsigned NOT NULL,
  `field` varchar(255) NOT NULL DEFAULT '',
  `data` varchar(14096) DEFAULT NULL,
  PRIMARY KEY (`user_id`,`field`),
  KEY `field` (`field`),
  KEY `index_ZZ_users_fb_data_on_user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Data exporting was unselected.
-- Dumping structure for view diveboard.shops_shared
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `shops_shared`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `shops_shared` AS select `shops`.`id` AS `id`,`shops`.`kind` AS `kind`,`shops`.`lat` AS `lat`,`shops`.`lng` AS `lng`,`shops`.`name` AS `name`,`shops`.`moderate` AS `moderate`,`shops`.`category` AS `category`,`shops`.`city` AS `city`,`shops`.`country_code` AS `country_code` from `shops`;

-- Dumping structure for view diveboard.shop_customers
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `shop_customers`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `shop_customers` AS select (`shop_customer_detail`.`shop_id` + (`shop_customer_detail`.`user_id` * 1000000)) AS `id`,`shop_customer_detail`.`shop_id` AS `shop_id`,`shop_customer_detail`.`user_id` AS `user_id`,count(`shop_customer_detail`.`dive_id`) AS `dive_count`,max(`shop_customer_detail`.`review_id`) AS `review_id`,count(`shop_customer_detail`.`basket_id`) AS `basket_count`,count(`shop_customer_detail`.`message_id_to`) AS `message_to_count`,count(`shop_customer_detail`.`message_id_from`) AS `message_from_count` from `shop_customer_detail` group by `shop_customer_detail`.`shop_id`,`shop_customer_detail`.`user_id`;

-- Dumping structure for view diveboard.shop_customer_detail
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `shop_customer_detail`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `shop_customer_detail` AS select `dives`.`shop_id` AS `shop_id`,`dives`.`user_id` AS `user_id`,'Dive' AS `stuff_type`,`dives`.`time_in` AS `registered_at`,`dives`.`id` AS `dive_id`,NULL AS `review_id`,NULL AS `basket_id`,NULL AS `message_id_from`,NULL AS `message_id_to` from `dives` where ((`dives`.`privacy` = 0) and (`dives`.`shop_id` is not null) and (`dives`.`user_id` is not null)) union all select `reviews`.`shop_id` AS `shop_id`,`reviews`.`user_id` AS `user_id`,'Review' AS `Review`,`reviews`.`created_at` AS `created_at`,NULL AS `NULL`,`reviews`.`id` AS `id`,NULL AS `NULL`,NULL AS `NULL`,NULL AS `NULL` from `reviews` where (`reviews`.`anonymous` = 0) union all select `baskets`.`shop_id` AS `shop_id`,`baskets`.`user_id` AS `user_id`,'Basket' AS `Basket`,ifnull(`baskets`.`paypal_order_date`,`baskets`.`created_at`) AS `IFNULL(baskets.paypal_order_date, baskets.created_at)`,NULL AS `NULL`,NULL AS `NULL`,`baskets`.`id` AS `id`,NULL AS `NULL`,NULL AS `NULL` from `baskets` where (`baskets`.`status` in ('paid','confirmed','hold','delivered','cancelled')) union all select `users`.`shop_proxy_id` AS `shop_proxy_id`,`internal_messages`.`from_id` AS `from_id`,'InternalMessage' AS `InternalMessage`,`internal_messages`.`created_at` AS `created_at`,NULL AS `NULL`,NULL AS `NULL`,NULL AS `NULL`,`internal_messages`.`id` AS `id`,NULL AS `NULL` from (`internal_messages` join `users`) where ((`internal_messages`.`to_id` = `users`.`id`) and (`users`.`shop_proxy_id` is not null)) union all select `users`.`shop_proxy_id` AS `shop_proxy_id`,`internal_messages`.`to_id` AS `to_id`,'InternalMessage' AS `InternalMessage`,`internal_messages`.`created_at` AS `created_at`,NULL AS `NULL`,NULL AS `NULL`,NULL AS `NULL`,NULL AS `NULL`,`internal_messages`.`id` AS `id` from (`internal_messages` join `users`) where ((`internal_messages`.`from_group_id` = `users`.`id`) and (`users`.`shop_proxy_id` is not null));

-- Dumping structure for view diveboard.shop_customer_history
-- Removing temporary table and create final VIEW structure
DROP TABLE IF EXISTS `shop_customer_history`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `shop_customer_history` AS select `shop_customer_detail`.`shop_id` AS `shop_id`,`shop_customer_detail`.`user_id` AS `user_id`,`shop_customer_detail`.`registered_at` AS `registered_at`,`shop_customer_detail`.`stuff_type` AS `stuff_type`,(case `shop_customer_detail`.`stuff_type` when 'Dive' then `shop_customer_detail`.`dive_id` when 'Review' then `shop_customer_detail`.`review_id` when 'Basket' then `shop_customer_detail`.`basket_id` when 'InternalMessage' then ifnull(`shop_customer_detail`.`message_id_from`,`shop_customer_detail`.`message_id_to`) else NULL end) AS `stuff_id` from `shop_customer_detail`;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IF(@OLD_FOREIGN_KEY_CHECKS IS NULL, 1, @OLD_FOREIGN_KEY_CHECKS) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
