![image alt text](/public/img/big_db_logo.png)

PUBLIC API SPECIFICATION

<table>
  <tr>
    <td>Date</td>
    <td>Version</td>
    <td>Comment</td>
  </tr>
  <tr>
    <td></td>
    <td>0.1</td>
    <td>First version of the specification</td>
  </tr>
  <tr>
    <td>April 25th 2012</td>
    <td>0.2</td>
    <td>Updated the vanity_url, login_email and login_fb apis
Updated behavior of how species array is being stored in dives (s- replaces c-)</td>
  </tr>
  <tr>
    <td>May 4th 2012</td>
    <td>0.3</td>
    <td>Deprecate use of location_id and region_id in setters, replaced by location object and region object
you must update your code from object_id => id to object => {"id" => id}</td>
  </tr>
  <tr>
    <td>October, 26th 2012</td>
    <td>0.4</td>
    <td>Adding the new calls and parameters
apikey gets mandatory</td>
  </tr>
  <tr>
    <td>December, 20th 2012</td>
    <td>0.5</td>
    <td>Support for comma separated flavours</td>
  </tr>
  <tr>
    <td>February, 5th 2014</td>
    <td>0.6</td>
    <td>Updated version, deprecating attributes without _value/_unit</td>
  </tr>
  <tr>
    <td>October 2nd 2014</td>
    <td>0.7</td>
    <td>added wallet pictures</td>
  </tr>
</table>


Table of content

[[TOC]]

# Terms of Use of the API

(a) To make it possible for Materials of the Site to be accessible to new technologies, we have developed a series of Application Programming Interfaces ("APIs") that allow for the Materials to be retrieved by technologies using certain computer programming methodologies. The APIs are freely available for anyone to use. You must register with the Site by emailing ‘[support@diveboard.com](mailto:support@diveboard.com)’ to indicate your desire to use them, which will allow us to better support your use of the API. Upon registration, a unique API key code will be issued to you which you will need to be including in upcoming requests as described in the API Documentation.

(b) If you develop a technology as a result of your use of the Site and the Materials on the Site, we encourage you to provide us with information about such technology. Sharing your success with us will help foster the Diveboard community by providing examples of success. We may choose to feature your story on the Site, or highlight your technology or product on the Site.

(c) The Data published through Diveboard is licenced under Creative Common’s [is licensed under a Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported License ](http://creativecommons.org/licenses/by-nc-nd/3.0/deed.en_US)![image alt text](/public/img/creative_commons.png) . Published data coming from Diveboard must link back to their location on Diveboard. Modification or corrections are only allowed through the APIs. If you are the original creator of a content you are free to push/pull/modify/delete such content. Diveboard may keep anonymized scientific data upon delete.

(d) You also agree to comply with the licenses associated with the Materials you acquire from the Site. You also agree to pass on all license terms and attributions associated with the objects as required by the licenses associated with those Materials.

(e) If you make use of our APIs, and should you wish to acquire all or major portions of the Materials from any individual content provider, you are required to contact that content provider directly.

(f) We reserve the right to monitor usage of our APIs and to discontinue access to the Site by users of the APIs who are determined to be in violation of this Agreement. If you have registered with us, we will make an effort to notify you of any potential violations. In addition to monitoring, we may maintain records of API use and information about the requestor.

# Introduction / Concepts

## Getting in touch

For any question about the API, please head to the #diveboard channel in irc.freenode.net.

## General Idea

The API was designed to be as generic as possible but still enabling complex and powerful actions.

The API is very (maybe too) close to the actual DB model, and was mostly built as an abstraction layer handling permission and CRUD functions. You can list objects (dives, spots, … ) update them (if you have the rights to), create new object.... and even create nested objects within a single API call.

## How to **test**

For testing purposes, you may want to try and use our staging environment. Beware that this environment has always new features, but it should still be stable.

Please do not make load testing with either environment without checking with us that it’s OK to do so !

<table>
  <tr>
    <td>Environment</td>
    <td>Usage</td>
    <td>URL</td>
  </tr>
  <tr>
    <td>Production</td>
    <td>Real life environment</td>
    <td>http://www.divaboard.com</td>
  </tr>
  <tr>
    <td>Staging</td>
    <td>Next version testing</td>
    <td>http://stage.diveboard.com</td>
  </tr>
</table>


# APIs

## Presentation

The APIs can be separated into 4 different kinds :

1. administrative calls (login)

2. object manipulation calls (read, create, update, delete dives, …)

3. search (spots, …)

4. file upload (profiles, pictures)

All POST call should send the parameters as "Content-Type: multipart/form-data;"

The ‘Walkthrough’ section gives examples on how to use the different APIs.

For privacy issues, all calls should always be done over HTTPS.

## Administrative functions

### Login with Facebook

#### Presentation

This call logs in a user by checking fbtoken + fbid and issues a token which should be used to make further API calls. The issued token has a 1 month validity by default, but please refer to the expiration string to be sure of that.

If the user is not registered on Diveboard, it will create an account linked with facebook authentication.

#### URL

<table>
  <tr>
    <td>HTTP method</td>
    <td>URL</td>
  </tr>
  <tr>
    <td>POST</td>
    <td>/api/login_fb</td>
  </tr>
</table>


#### HTTP parameters

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>fbid</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>User's Facebook ID</td>
  </tr>
  <tr>
    <td>fbtoken</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>User's Facebook Token (as given by facebook)</td>
  </tr>
  <tr>
    <td>apikey</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>the application's API key</td>
  </tr>
</table>


#### Output

The body of the response is a JSON string, which contains a Hash. The attributes of this Hash are described in the table here.

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>success</td>
    <td>BOOLEAN</td>
    <td>M</td>
    <td>N</td>
    <td>false only if a big error</td>
  </tr>
  <tr>
    <td>error</td>
    <td>STRING XXX</td>
    <td>O</td>
    <td>N</td>
    <td>string defining the error (only present if success==false)</td>
  </tr>
  <tr>
    <td>error_tag</td>
    <td>String</td>
    <td>O</td>
    <td>N</td>
    <td>id of the error (only present if success==false)
This id should be provided when available to report bugs to Diveboard.</td>
  </tr>
  <tr>
    <td>token</td>
    <td>String</td>
    <td>M</td>
    <td>N</td>
    <td>string with the authentication token to use</td>
  </tr>
  <tr>
    <td>vanity_url_defined Deprecated</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>expiration</td>
    <td>STRING
"2012-05-02T14:48:09Z"</td>
    <td>M</td>
    <td>N</td>
    <td>Date when the token expires - 1day (prevent all timezone craze)</td>
  </tr>
  <tr>
    <td>id</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>Shaken ID of the new user</td>
  </tr>
  <tr>
    <td>units Deprecated</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>preferred_units</td>
    <td>UNITS Object</td>
    <td>M</td>
    <td>N</td>
    <td>User preference about units</td>
  </tr>
  <tr>
    <td>new_account</td>
    <td>BOOLEAN</td>
    <td>M</td>
    <td>N</td>
    <td>True if an account was created</td>
  </tr>
  <tr>
    <td>user</td>
    <td>USER Object</td>
    <td>M</td>
    <td>N</td>
    <td>The User object rendered with a "private" flavour</td>
  </tr>
</table>


### Login with Email/Password

#### Presentation

This call logs in a user by checking the email and password, and issues a token which should be used to make further API calls. The issued token has a 1 month validity by default, but please refer to the expiration string to be sure of that.

If the user is not registered on Diveboard, it will create an account. In this case, the ‘vanity_url_defined’ attribute will be set to ‘true’ and you should make a call to ‘api/register_vanity_url’ to finish the registration process.

#### URL

<table>
  <tr>
    <td>HTTP method</td>
    <td>URL</td>
  </tr>
  <tr>
    <td>POST</td>
    <td>/api/login_email</td>
  </tr>
</table>


#### HTTP parameters

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>email</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>User's email</td>
  </tr>
  <tr>
    <td>password</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>User’s plaintext password</td>
  </tr>
  <tr>
    <td>apikey</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>the application's API key</td>
  </tr>
</table>


#### *Output*

The body of the response is a JSON string, which contains a Hash. The attributes of this Hash are described in the table here.

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>success</td>
    <td>BOOLEAN</td>
    <td>M</td>
    <td>N</td>
    <td>false only if a big error</td>
  </tr>
  <tr>
    <td>error</td>
    <td>STRING XXX</td>
    <td>O</td>
    <td>N</td>
    <td>string defining the error (only present if success==false)</td>
  </tr>
  <tr>
    <td>error_tag</td>
    <td>String</td>
    <td>O</td>
    <td>N</td>
    <td>id of the error (only present if success==false)
This id should be provided when available to report bugs to Diveboard.</td>
  </tr>
  <tr>
    <td>units
Deprecated</td>
    <td>JSON Object</td>
    <td>O</td>
    <td>Y</td>
    <td></td>
  </tr>
  <tr>
    <td>preferred_units</td>
    <td>UNITS Object</td>
    <td>M</td>
    <td>N</td>
    <td>User preference about units</td>
  </tr>
  <tr>
    <td>token</td>
    <td>String</td>
    <td>M</td>
    <td>N</td>
    <td>string with the authentication token to use</td>
  </tr>
  <tr>
    <td>expiration</td>
    <td>STRING
"2012-05-02T14:48:09Z"</td>
    <td>M</td>
    <td>N</td>
    <td>Date when the token expires - 1day (prevent all timezone craze)</td>
  </tr>
  <tr>
    <td>id</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>id of the user</td>
  </tr>
  <tr>
    <td>new_account</td>
    <td>BOOLEAN</td>
    <td>M</td>
    <td>N</td>
    <td>True if an account was created</td>
  </tr>
  <tr>
    <td>user</td>
    <td>USER Object</td>
    <td>M</td>
    <td>N</td>
    <td>The User object rendered with a "private" flavour</td>
  </tr>
</table>




### Change a vanity_url

#### Presentation

This call will change a vanity url of a user.

#### URL

<table>
  <tr>
    <td>HTTP method</td>
    <td>URL</td>
  </tr>
  <tr>
    <td>POST</td>
    <td>/api/register_vanity_url</td>
  </tr>
</table>


#### HTTP parameters

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>token</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>User’s authentication token</td>
  </tr>
  <tr>
    <td>vanity_url</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>Chosen vanity URL</td>
  </tr>
  <tr>
    <td>apikey</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>the application's API key</td>
  </tr>
</table>


#### Output

The body of the response is a JSON string, which contains a Hash. The attributes of this Hash are described in the table here.

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>success</td>
    <td>BOOLEAN</td>
    <td>M</td>
    <td>N</td>
    <td>false only if a big error</td>
  </tr>
  <tr>
    <td>error</td>
    <td>STRING</td>
    <td>O</td>
    <td>N</td>
    <td>string defining the error (only present if success==false)</td>
  </tr>
  <tr>
    <td>error_tag</td>
    <td>String</td>
    <td>O</td>
    <td>N</td>
    <td>id of the error (only present if success==false)
This id should be provided when available to report bugs to Diveboard.</td>
  </tr>
</table>


## Object Manipulation

### Presentation

The set of API for object manipulation uses the same logic for all objects. It is based on JSON objects.

When updating an object, some attributes may be rejected while others will be accepted. As a general rule, all the valid changes will be taken into account and applied, and only the invalid changes will be discarded. This mean that if you’re updating both the duration and the gears of a dive with a correct duration but an invalid gear, the change on duration will be applied but the change of gear will not be applied. The answer will notify you of the error on the gear update.

To have the details of the objects that can be passed, please refer to the section "Objects". For a better understanding of how to manipulate these calls, you should have a look at the "Walkthrough" section.

### URL

<table>
  <tr>
    <td>Type of object</td>
    <td>HTTP method</td>
    <td>URL</td>
  </tr>
  <tr>
    <td>user</td>
    <td>read : POST
create : POST
update : POST
delete : not available</td>
    <td>/api/V2/user
/api/V2/user/_id_</td>
  </tr>
  <tr>
    <td>dive</td>
    <td>read : POST
create : POST
update : POST
delete : DELETE</td>
    <td>/api/V2/dive
/api/V2/dive/_id_</td>
  </tr>
  <tr>
    <td>spot</td>
    <td>read : POST
create : POST
update : POST
delete : not available</td>
    <td>/api/V2/spot
/api/V2/spot/_id_</td>
  </tr>
  <tr>
    <td>shop</td>
    <td>read : POST
create : POST
update : POST
delete : not available</td>
    <td>/api/V2/shop
/api/V2/shop/_id_</td>
  </tr>
  <tr>
    <td>review</td>
    <td>read : POST
create : POST
update : POST
delete : DELETE</td>
    <td>/api/V2/review
/api/V2/review/_id_</td>
  </tr>
  <tr>
    <td>notif</td>
    <td>read : POST
create : POST
update : POST
delete : DELETE</td>
    <td>/api/V2/notif
/api/V2/notif/_id_</td>
  </tr>
</table>


### HTTP parameters

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>flavour</td>
    <td>string</td>
    <td>O</td>
    <td>Y</td>
    <td>One or several flavours separated by comma. This will command the level of detail for each object in the response.
e.g. "private,dive_profile"</td>
  </tr>
  <tr>
    <td>arg</td>
    <td>JSON STRING of OBJECT
or
JSON STRING of ARRAY of OBJECT</td>
    <td>M</td>
    <td>N</td>
    <td>JSON string describing the object to read, create, update or delete.
</td>
  </tr>
  <tr>
    <td>auth_token</td>
    <td>STRING</td>
    <td>O</td>
    <td>N</td>
    <td>authentication string</td>
  </tr>
  <tr>
    <td>apikey</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>API key</td>
  </tr>
</table>


### Output

The body of the response is a JSON string, which contains a Hash. The attributes of this Hash are described in the table here.

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>success</td>
    <td>BOOLEAN</td>
    <td>M</td>
    <td>N</td>
    <td>false only if a big error</td>
  </tr>
  <tr>
    <td>error</td>
    <td>ARRAY of STRING
or.....
ARRAY of OBJECT ERROR</td>
    <td>O</td>
    <td>N</td>
    <td>errors can be reported even if success is true. For example, when updating an object, some attributes may be rejected while others will be accepted.</td>
  </tr>
  <tr>
    <td>result</td>
    <td>OBJECT</td>
    <td>O</td>
    <td>Y</td>
    <td>only if no error</td>
  </tr>
  <tr>
    <td>error_tag</td>
    <td>String</td>
    <td>O</td>
    <td>N</td>
    <td>id of the error (only present if success==false)
This id should be provided when available to report bugs to Diveboard.</td>
  </tr>
</table>


### Examples

Here are a few simple example calls to read users detail and create a new dive. Please refer to the "Walkthrough" section for more complex examples.

To get the details of a user :

<table>
  <tr>
    <td>REQUEST</td>
    <td>curl -X GET "http://www.diveboard.com/api/V2/user/48" -F "apikey=xxXXX6XXX6XxxxX6XXXX"</td>
  </tr>
  <tr>
    <td>RESPONSE</td>
    <td>{"success":true,"error":[],"result":{"id":48,"vanity_url":"pascal","nickname":"Pascal", …................ }}</td>
  </tr>
</table>


To get more detail for a user, use a different flavour (cf. the object section to get the list of values per parameter) :

<table>
  <tr>
    <td>REQUEST</td>
    <td>curl "http://www.diveboard.com/api/V2/user"
-F 'arg={"id":48}'
-F 'flavour=private'
-F 'auth_token=ip4rHSSD9/diOWR3szonh7ikbhl0k9g/UgMSTBfjb00='
-F "apikey=xxXXX6XXX6XxxxX6XXXX"</td>
  </tr>
  <tr>
    <td>RESPONSE</td>
    <td>{"success":true,"error":[],"result":{"flavour":"private","id":48,"vanity_url":"pascal","nickname":"Pascal", "pict":true, …................ }}</td>
  </tr>
</table>


To create a new element, just send the data without specifying an id. You will get the id in the returned object detail :

<table>
  <tr>
    <td>REQUEST</td>
    <td>curl -s "http://l.dev.diveboard.com/api/V2/dive"
-F 'auth_token=UEEnVPDmErqKIKhI952vcQMnU1qbTQ/WxlXsnXUNBoY='
-F "apikey=j9icv6zlgwq9"
-F 'arg={"user_id": 12885, "duration": 90, "maxdepth":40, "time_in": "2011-10-16T09:40:00Z", "spot": {"name":"Blue hole", "country_code":"MT","location":{"name":"Gozo"}, "region":{"name":"Mediterranean Sea"}}}'</td>
  </tr>
  <tr>
    <td>RESPONSE</td>
    <td>{"success":true,"error":[],"result":{"class":"Dive","flavour":"public","id":31722,"shaken_id":"D6fQS5L","time_in":"2011-10-16T09:40:00Z","duration":90,"maxdepth":40.0,"user_id":12885,"spot_id":21481,"temp_surface":null,"temp_bottom":null,"privacy":0,"weights":null,"safetystops":null,"divetype":[],"favorite":null,"buddy":[],"visibility":null,"trip_name":null,"water":null,"altitude":0,"fullpermalink":"http://l.dev.diveboard.com//D6fQS5L","permalink":"//D6fQS5L","complete":true,"thumbnail_image_url":"http://l1.dev.diveboard.com/map_images/map_21481.jpg","thumbnail_profile_url":null,"guide":null,"shop_id":null,"notes":null,"public_notes":null,"diveshop":null,"current":null,"species":[],"gears":[],"user_gears":[],"dive_gears":[],"date":"2011-10-16","time":"09:40"},"user_authentified":true}</td>
  </tr>
</table>


To update an element, you only need to provide the id of the element you wish to update and the parameters that need to be updated. The other details will not be changed.

<table>
  <tr>
    <td>REQUEST</td>
    <td>curl "http://www.diveboard.com/api/V2/dive"
-F "auth_token=ip4rHSSD9/diOWR3szonh7ikbhl0k9g/UgMSTBfjb00="
-F "apikey=xxXXX6XXX6XxxxX6XXXX"
-F 'arg={"id":10306,"duration":120}'</td>
  </tr>
  <tr>
    <td>RESPONSE</td>
    <td>{"success":true,"error":[],"result":{"class":"Dive","flavour":"public","id":10306,"time_in":"2011-10-16T09:40:00Z","duration":120,"maxdepth":"40.0","user_id":32,"spot_id":1843,"temp_surface":null,"temp_bottom":null,"privacy":0,"weights":null,"safetystops":null,"divetype":[],"favorite":null,"buddy":[],"visibility":null,"trip_name":null,"water":null,"altitude":0,"fullpermalink":"http://www.diveboard.com/duncan.farthing/10306","complete":false,"thumbnail_image_url":"http://www.diveboard.com/map_images/map_1.jpg","thumbnail_profile_url":null,"species":[],"guide":null,"shop_id":null,"notes":null,"public_notes":null,"diveshop":null,"gears":[],"user_gears":[],"dive_gears":[],"date":"2011-10-16","time":"09:40"}}</td>
  </tr>
</table>




## Search

### Spots

#### Presentation

This API will let you search spot base from a lat/long OR a name.

If an auth_token and apikey is passed, user will be logged and will access his private spots (if any)

#### URL

<table>
  <tr>
    <td>HTTP method</td>
    <td>URL</td>
  </tr>
  <tr>
    <td>GET/POST</td>
    <td>/api/search/spot</td>
  </tr>
</table>


#### HTTP parameters

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>q</td>
    <td>STRING</td>
    <td>O</td>
    <td>N</td>
    <td>name to search</td>
  </tr>
  <tr>
    <td>lat</td>
    <td>FLOAT</td>
    <td>O</td>
    <td>N</td>
    <td>latitude in degrees</td>
  </tr>
  <tr>
    <td>lng</td>
    <td>FLOAT</td>
    <td>O</td>
    <td>N</td>
    <td>longitude in degrees</td>
  </tr>
  <tr>
    <td>apikey</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>Api key</td>
  </tr>
  <tr>
    <td>auth_token</td>
    <td>STRING</td>
    <td>O</td>
    <td>N</td>
    <td>user auth token</td>
  </tr>
</table>


#### Output

The body of the response is a JSON HASH, which contains an ARRAY of maximum 50 answers. The attributes of this Hash are described in the table here.

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>sucess</td>
    <td>BOOLEAN</td>
    <td>M</td>
    <td>N</td>
    <td>true/false</td>
  </tr>
  <tr>
    <td>data</td>
    <td>JSON ARRAY (see below)</td>
    <td>M</td>
    <td>N</td>
    <td>array of spot data</td>
  </tr>
  <tr>
    <td>error</td>
    <td>STRING</td>
    <td>O</td>
    <td>Y</td>
    <td>error explained</td>
  </tr>
</table>


data :

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>name</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>a formatted name of the spot i.e. "White River (Greece - Cyprus)"</td>
  </tr>
  <tr>
    <td>id</td>
    <td>INTEGER</td>
    <td>M</td>
    <td>N</td>
    <td>spot ID</td>
  </tr>
  <tr>
    <td>data</td>
    <td>SPOT object, public flavour</td>
    <td>M</td>
    <td>N</td>
    <td>SPOT Object, public flavour</td>
  </tr>
</table>


### Species

#### Presentation

This API will let you search **species** base for a name or search for family of a given id( ancestors...).

On species search only species are returned (no other taxonrank)

IDs have 2 formats : s-12345 for scientific names and c-12345 for common names … they are STRINGS

#### URL

<table>
  <tr>
    <td>HTTP method</td>
    <td>URL</td>
  </tr>
  <tr>
    <td>POST</td>
    <td>/api/fishsearch_extended</td>
  </tr>
</table>


#### HTTP parameters

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>name</td>
    <td>STRING</td>
    <td>O</td>
    <td>N</td>
    <td>name to search</td>
  </tr>
  <tr>
    <td>id</td>
    <td>STRING</td>
    <td>O</td>
    <td>N</td>
    <td>the id of a base species (s-xxxx or c-xxxx)</td>
  </tr>
  <tr>
    <td>scope</td>
    <td>STRING</td>
    <td>O</td>
    <td>N</td>
    <td>"children", "siblings", "ancestors" for a given id - only works if id is given </td>
  </tr>
  <tr>
    <td>page_size</td>
    <td>Integer</td>
    <td>O</td>
    <td>N</td>
    <td>number of results per page</td>
  </tr>
  <tr>
    <td>page</td>
    <td>INTEGER</td>
    <td>O</td>
    <td>N</td>
    <td>page number</td>
  </tr>
  <tr>
    <td>apikey</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>Api key</td>
  </tr>
</table>


#### Output

The body of the response is a JSON HASH, which contains an ARRAY of maximum 50 answers. The attributes of this Hash are described in the table here.

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>sucess</td>
    <td>BOOLEAN</td>
    <td>M</td>
    <td>N</td>
    <td>true/false</td>
  </tr>
  <tr>
    <td>result</td>
    <td>JSON ARRAY of SPECIES</td>
    <td>M</td>
    <td>N</td>
    <td>array of spot data</td>
  </tr>
  <tr>
    <td>paginate</td>
    <td>JSON paginate object</td>
    <td>M</td>
    <td>N</td>
    <td>"paginate":{"next":null,"previous":null,"total":5,"total_pages":1,"current_page":1}</td>
  </tr>
  <tr>
    <td>error</td>
    <td>STRING</td>
    <td>O</td>
    <td>Y</td>
    <td>error explained</td>
  </tr>
</table>


data :

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>id</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>"s-13124" or "c-124214"</td>
  </tr>
  <tr>
    <td>sname</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>scientific name</td>
  </tr>
  <tr>
    <td>cname</td>
    <td>STRING ARRAY</td>
    <td>M</td>
    <td>Y</td>
    <td>list of common names</td>
  </tr>
  <tr>
    <td>preferred_name</td>
    <td>STRING</td>
    <td>M</td>
    <td>Y</td>
    <td>Preferred common name</td>
  </tr>
  <tr>
    <td>picture</td>
    <td>STRING</td>
    <td>M</td>
    <td>Y</td>
    <td>link to a picture</td>
  </tr>
  <tr>
    <td>bio</td>
    <td>STRING</td>
    <td>M</td>
    <td>Y</td>
    <td>Biological info from EOL</td>
  </tr>
  <tr>
    <td>rank</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>taxon rank</td>
  </tr>
  <tr>
    <td>category</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>what family the fish belong to </td>
  </tr>
  <tr>
    <td>data</td>
    <td>SPOT object, public flavour</td>
    <td>M</td>
    <td>N</td>
    <td>SPOT Object, public flavour</td>
  </tr>
</table>


## Uploading files

### Profile upload

#### Presentation

This API needs to be used before assigning or creating a dive with a given profile. As of version 0.1, it supports UDCF and DL7 file formats.

#### URL

<table>
  <tr>
    <td>HTTP method</td>
    <td>URL</td>
  </tr>
  <tr>
    <td>POST</td>
    <td>/api/upload_profile</td>
  </tr>
</table>


#### HTTP parameters

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>token</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>token for the user</td>
  </tr>
  <tr>
    <td>filename</td>
    <td>BINARY</td>
    <td>M</td>
    <td>N</td>
    <td>content of the file</td>
  </tr>
  <tr>
    <td>apikey</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>Api key</td>
  </tr>
</table>


#### Output

The body of the response is a JSON string, which contains a Hash. The attributes of this Hash are described in the table here.

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>success</td>
    <td>BOOLEAN</td>
    <td>M</td>
    <td>N</td>
    <td></td>
  </tr>
  <tr>
    <td>error</td>
    <td>STRING</td>
    <td>O</td>
    <td>N</td>
    <td></td>
  </tr>
  <tr>
    <td>nbdives</td>
    <td>INTEGER</td>
    <td>M</td>
    <td>N</td>
    <td>number of dives found in the uploaded file</td>
  </tr>
  <tr>
    <td>dive_summary</td>
    <td>ARRAY of HASH</td>
    <td>M</td>
    <td>N</td>
    <td>For each dive found in the file, a summary of the dive is reported in a hash containing the following keys :
- number: 0 : the number of the dive in the file (if file has many dives)
- date: "2010-07-28" : date of the dive as in the file
- time: "21:18" : the time in HH:MM
- duration: 77 : in minutes
- max_depth: 7.9 : in meters
- maxtemp: 25 : in celsius
- mintemp: 2 : in celsius
- newdive: true : does it look like a new dive or a profile the user already has uploaded ?</td>
  </tr>
  <tr>
    <td>fileid</td>
    <td>INTEGER</td>
    <td>M</td>
    <td>N</td>
    <td>ID of the uploaded file</td>
  </tr>
</table>




### Picture upload

#### Presentation

 ‘TODO XXX’

#### URL

<table>
  <tr>
    <td>HTTP method</td>
    <td>URL</td>
  </tr>
  <tr>
    <td>POST</td>
    <td>/api/picture/upload</td>
  </tr>
</table>


#### HTTP parameters

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>qqfile</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
</table>


#### Output

The body of the response is a JSON string, which contains a Hash. The attributes of this Hash are described in the table here.

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
</table>


# WALKTHROUGH

## Logging in

<table>
  <tr>
    <td>Example to log in a user with his facebook ID and facebook token</td>
  </tr>
  <tr>
    <td>curl -s "http://stage.diveboard.com/api/login_fb"
-F "fbid=100004637132223"
-F "fbtoken=AAABzYDF4nt0BAL1e0gF86RRV4xoRu2rZAmXxJerM4IJLbXLZBNm2KiVXYD7ZBakiNgreUP5yPDMwqpYIhKnoNnIK"
-F "apikey=hwkzq4rhw9lq"</td>
  </tr>
  <tr>
    <td>{"success":true,"token":"wtV6sxKrMdXXBV+dVrqhJs936KKrq0TQBw2toWjM+Lk=","expiration":"2012-11-26T19:57:44Z","vanity_url_defined":false,"units":{"distance":"Km","weight":"Kg","temperature":"C","pressure":"bar"},"id":"U3T7iSQ"}</td>
  </tr>
</table>


## Reading an object

To get an object with a given flavour from an id, you need to call the given API and pass as argument only the ‘id’ value in the ‘arg’ hash.

<table>
  <tr>
    <td>Example to get the basic details for a user</td>
  </tr>
  <tr>
    <td>curl -s "http://stage.diveboard.com/api/V2/user/U3T7iSQ"
-F "apikey=hwkzq4rhw9lq"</td>
  </tr>
  <tr>
    <td>{"success":true,"error":[],"result":{"class":"User","flavour":"public","id":12850,"shaken_id":"U3T7iSQ","vanity_url":null,"qualifications":{},"picture":"http://graph.facebook.com/100004637132223/picture?type=normal","picture_small":"http://graph.facebook.com/100004637132223/picture?type=square","picture_large":"http://graph.facebook.com/100004637132223/picture?type=large","full_permalink":"http://stage.diveboard.com/","total_nb_dives":0,"public_nb_dives":0,"public_dive_ids":[],"nickname":"David Narayanansen"},"user_authentified":false}</td>
  </tr>
</table>


## Creating an object

Creating an object is similar to updating an object.... but since you don’t know what ‘id’ the object will get, then just don’t supply it ! If everything went correctly, you’ll get the JSON of the object in the response, and you may then get the attributed ‘id’ for further updates.

<table>
  <tr>
    <td>Example to create a new dive</td>
  </tr>
  <tr>
    <td>curl -s "http://stage.diveboard.com/api/V2/dive"
-F 'auth_token=wtV6sxKrMdXXBV+dVrqhJs936KKrq0TQBw2toWjM+Lk='
-F "apikey=hwkzq4rhw9lq"
-F 'arg={"user_id": "U3T7iSQ", "duration": 90, "maxdepth":40, "time_in": "2011-10-16T09:40:00Z", "spot":{"id":1843}}'</td>
  </tr>
  <tr>
    <td>{"success":true,"error":[],"result":{"class":"Dive","flavour":"public","id":31671,"shaken_id":"D3eyz9U","time_in":"2011-10-16T09:40:00Z","duration":90,"maxdepth":40.0,"user_id":12850,"spot_id":1843,"temp_surface":null,"temp_bottom":null,"privacy":0,"weights":null,"safetystops":null,"divetype":[],"favorite":null,"buddy":[],"visibility":null,"trip_name":null,"water":null,"altitude":0,"fullpermalink":"http://stage.diveboard.com//D3eyz9U","permalink":"//D3eyz9U","complete":true,"thumbnail_image_url":"http://stage.diveboard.com/map_images/map_1843.jpg","thumbnail_profile_url":null,"guide":null,"shop_id":null,"notes":null,"public_notes":null,"diveshop":null,"current":null,"species":[],"gears":[],"user_gears":[],"dive_gears":[],"date":"2011-10-16","time":"09:40"},"user_authentified":true}</td>
  </tr>
</table>


## Updating part of an object

To update some attributes from an object, you need to pass the ‘id’ of the object and then include in the ‘arg’ hash only the attributes you wish to modify. Please note that if you include one attribute with a ‘null’ value, we will try to overwrite that attribute in the database to null. So be careful to send only the attributes you wish to update, or make sure you send the exact same value.

<table>
  <tr>
    <td>Example to update the nickname of a user</td>
  </tr>
  <tr>
    <td>curl -s "http://stage.diveboard.com/api/V2/user"
-F 'arg={"id":"12850", "nickname":"New Nick"}'
-F 'auth_token=wtV6sxKrMdXXBV+dVrqhJs936KKrq0TQBw2toWjM+Lk='
-F "apikey=hwkzq4rhw9lq"</td>
  </tr>
  <tr>
    <td>{"success":true,"error":[],"result":{"class":"User","flavour":"public","id":12850,"shaken_id":"U3T7iSQ","vanity_url":null,"qualifications":{},"picture":"http://graph.facebook.com/100004637132223/picture?type=normal","picture_small":"http://graph.facebook.com/100004637132223/picture?type=square","picture_large":"http://graph.facebook.com/100004637132223/picture?type=large","full_permalink":"http://stage.diveboard.com/","total_nb_dives":0,"public_nb_dives":0,"public_dive_ids":[],"nickname":"New Nick"},"user_authentified":true}</td>
  </tr>
</table>


<table>
  <tr>
    <td>Example to update both the duration and the depth on a dive</td>
  </tr>
  <tr>
    <td>curl -s "http://stage.diveboard.com/api/V2/dive"
-F 'auth_token=wtV6sxKrMdXXBV+dVrqhJs936KKrq0TQBw2toWjM+Lk='
-F "apikey=hwkzq4rhw9lq"
-F 'arg={"id": "31671", "duration": 50, "maxdepth":50}'</td>
  </tr>
  <tr>
    <td>{"success":true,"error":[],"result":{"class":"Dive","flavour":"public","id":31671,"shaken_id":"D3eyz9U","time_in":"2011-10-16T09:40:00Z","duration":50,"maxdepth":50.0,"user_id":12850,"spot_id":1843,"temp_surface":null,"temp_bottom":null,"privacy":0,"weights":null,"safetystops":null,"divetype":[],"favorite":null,"buddy":[],"visibility":null,"trip_name":null,"water":null,"altitude":0,"fullpermalink":"http://stage.diveboard.com//D3eyz9U","permalink":"//D3eyz9U","complete":true,"thumbnail_image_url":"http://stage.diveboard.com/map_images/map_1843.jpg","thumbnail_profile_url":null,"guide":null,"shop_id":null,"notes":null,"public_notes":null,"diveshop":null,"current":null,"species":[],"gears":[],"user_gears":[],"dive_gears":[],"date":"2011-10-16","time":"09:40"},"user_authentified":true}</td>
  </tr>
</table>


<table>
  <tr>
    <td>Example to add a dive profile to a dive</td>
  </tr>
  <tr>
    <td>curl -s "http://stage.diveboard.com/api/V2/dive"
-F 'auth_token=z61mYD1bUa7xCJBAfOqcBmy8I/rGGpkMKrQS5dOaHio='
-F "apikey=76soje9nvcne"
-F 'flavour=public_with_profile'
-F 'arg={"id": "31678", "raw_profile":[{"seconds":0, "depth":0}, {"seconds":30, "depth":3}, {"seconds":60, "depth":5}, {"seconds":90, "depth":10}, {"seconds":2900, "depth":10}, {"seconds":3000, "depth":0} ]}'</td>
  </tr>
  <tr>
    <td>{"success":true,"error":[],"result":{"class":"Dive","flavour":"public_with_profile","id":31678,"shaken_id":"D44ZZwl","time_in":"2011-10-16T09:40:00Z","duration":50,"maxdepth":50.0,"user_id":12855,"spot_id":1843,"temp_surface":null,"temp_bottom":null,"privacy":0,"weights":null,"safetystops":null,"divetype":[],"favorite":null,"buddy":[],"visibility":null,"trip_name":null,"water":null,"altitude":0,"fullpermalink":"http://stage.diveboard.com//D44ZZwl","permalink":"//D44ZZwl","complete":true,"thumbnail_image_url":"http://stage.diveboard.com/map_images/map_1843.jpg","thumbnail_profile_url":"http://stage.diveboard.com//31678/profile.png?g=small_or&u=m","guide":null,"shop_id":null,"notes":null,"public_notes":null,"diveshop":null,"current":null,"species":[],"gears":[],"user_gears":[],"dive_gears":[],"date":"2011-10-16","time":"09:40","raw_profile":[{"class":"ProfileData","flavour":"public","seconds":0,"depth":0.0,"current_water_temperature":null,"main_cylinder_pressure":null,"heart_beats":null,"deco_violation":false,"deco_start":false,"ascent_violation":false,"bookmark":false,"surface_event":false},{"class":"ProfileData","flavour":"public","seconds":30,"depth":3.0,"current_water_temperature":null,"main_cylinder_pressure":null,"heart_beats":null,"deco_violation":false,"deco_start":false,"ascent_violation":false,"bookmark":false,"surface_event":false},{"class":"ProfileData","flavour":"public","seconds":60,"depth":5.0,"current_water_temperature":null,"main_cylinder_pressure":null,"heart_beats":null,"deco_violation":false,"deco_start":false,"ascent_violation":false,"bookmark":false,"surface_event":false},{"class":"ProfileData","flavour":"public","seconds":90,"depth":10.0,"current_water_temperature":null,"main_cylinder_pressure":null,"heart_beats":null,"deco_violation":false,"deco_start":false,"ascent_violation":false,"bookmark":false,"surface_event":false},{"class":"ProfileData","flavour":"public","seconds":2900,"depth":10.0,"current_water_temperature":null,"main_cylinder_pressure":null,"heart_beats":null,"deco_violation":false,"deco_start":false,"ascent_violation":false,"bookmark":false,"surface_event":false},{"class":"ProfileData","flavour":"public","seconds":3000,"depth":0.0,"current_water_temperature":null,"main_cylinder_pressure":null,"heart_beats":null,"deco_violation":false,"deco_start":false,"ascent_violation":false,"bookmark":false,"surface_event":false}]},"user_authentified":true}</td>
  </tr>
</table>


## Adding or removing a pre-existing element in a list

As for the standard attribute update, you need to pass the ‘id’ of the object and then include in the ‘arg’ hash only the attributes you wish to modify. Now, for lists, you need to supply the whole list of elements. For existing objects, you don’t need to send back the whole details of the sub-objects : just their ‘id’ is sufficient. This means for example that to add an element you need to supply the previous list plus the new element.

<table>
  <tr>
    <td>Example to add a gear to a dive</td>
  </tr>
  <tr>
    <td>curl -s "http://stage.diveboard.com/api/V2/user"
-F 'auth_token=wtV6sxKrMdXXBV+dVrqhJs936KKrq0TQBw2toWjM+Lk='
-F 'flavour=private'
-F "apikey=hwkzq4rhw9lq"
-F 'arg={"id":"12850", "user_gears": [{"category":"Computer", "model":"Vyper", "manufacturer":"Suunto"}]}'</td>
  </tr>
  <tr>
    <td>{"success":true,"error":[],"result":{"class":"User","flavour":"private","id":12850,"shaken_id":"U3T7iSQ","vanity_url":null,"qualifications":{},"picture":"http://graph.facebook.com/100004637132223/picture?type=normal","picture_small":"http://graph.facebook.com/100004637132223/picture?type=square","picture_large":"http://graph.facebook.com/100004637132223/picture?type=large","full_permalink":"http://stage.diveboard.com/","total_nb_dives":1,"public_nb_dives":1,"public_dive_ids":[31671],"nickname":"New Nick","dan_data":null,"storage_used":{"dive_pictures":0,"monthly_dive_pictures":0,"orphan_pictures":0,"all_pictures":0},"quota_type":"per_month","quota_limit":524288000,"all_dive_ids":[31671],"pict":false,"advertisements":[],"ad_album_id":30711,"user_gears":[{"class":"UserGear","flavour":"private","category":"Computer","id":2106,"manufacturer":"Suunto","model":"Vyper","featured":null,"acquisition":null,"last_revision":null,"reference":null,"auto_feature":"never"}]},"user_authentified":true}</td>
  </tr>
</table>


<table>
  <tr>
    <td>Example to remove all user_gears from a dive</td>
  </tr>
  <tr>
    <td>curl -s "http://stage.diveboard.com/api/V2/user"
-F 'auth_token=wtV6sxKrMdXXBV+dVrqhJs936KKrq0TQBw2toWjM+Lk='
-F 'flavour=private'
-F "apikey=hwkzq4rhw9lq"
-F 'arg={"id":"12850", "user_gears": []}'</td>
  </tr>
  <tr>
    <td>{"success":true,"error":[],"result":{"class":"User","flavour":"private","id":12850,"shaken_id":"U3T7iSQ","vanity_url":null,"qualifications":{},"picture":"http://graph.facebook.com/100004637132223/picture?type=normal","picture_small":"http://graph.facebook.com/100004637132223/picture?type=square","picture_large":"http://graph.facebook.com/100004637132223/picture?type=large","full_permalink":"http://stage.diveboard.com/","total_nb_dives":1,"public_nb_dives":1,"public_dive_ids":[31671],"nickname":"New Nick","dan_data":null,"storage_used":{"dive_pictures":0,"monthly_dive_pictures":0,"orphan_pictures":0,"all_pictures":0},"quota_type":"per_month","quota_limit":524288000,"all_dive_ids":[31671],"pict":false,"advertisements":[],"ad_album_id":30711,"user_gears":[]},"user_authentified":true}</td>
  </tr>
</table>


## Deleting an object

To delete an object, the HTTP method to use is DELETE

<table>
  <tr>
    <td>Example to delete a dive</td>
  </tr>
  <tr>
    <td>curl -X DELETE -s "http://stage.diveboard.com/api/V2/dive/31671"
-F 'auth_token=wtV6sxKrMdXXBV+dVrqhJs936KKrq0TQBw2toWjM+Lk='
-F "apikey=hwkzq4rhw9lq"</td>
  </tr>
  <tr>
    <td>{"success":true,"result":null,"error":[],"user_authentified":true}</td>
  </tr>
</table>


## Creating several objects of the same type at the same time

In order to make batch creation easier, the ‘arg’ parameter may accept an array of Hash that all describe the same type of objects.

<table>
  <tr>
    <td>Example to create 2 different dives at the same time</td>
  </tr>
  <tr>
    <td>curl -s "http://stage.diveboard.com/api/V2/dive"
-F 'auth_token=wtV6sxKrMdXXBV+dVrqhJs936KKrq0TQBw2toWjM+Lk='
-F "apikey=hwkzq4rhw9lq"
-F 'arg=[{"user_id": "U3T7iSQ", "duration": 90, "maxdepth":40, "time_in": "2011-10-16T09:40:00Z", "spot":{"id":1843}},{"user_id": "U3T7iSQ", "duration": 50, "maxdepth":50, "time_in": "2011-10-17T09:40:00Z", "spot":{"id":1843}}]'</td>
  </tr>
  <tr>
    <td>{"success":true,"error":[],"result":[{"class":"Dive","flavour":"public","id":31672,"shaken_id":"D3iddpx","time_in":"2011-10-16T09:40:00Z","duration":90,"maxdepth":40.0,"user_id":12850,"spot_id":1843,"temp_surface":null,"temp_bottom":null,"privacy":0,"weights":null,"safetystops":null,"divetype":[],"favorite":null,"buddy":[],"visibility":null,"trip_name":null,"water":null,"altitude":0,"fullpermalink":"http://stage.diveboard.com//D3iddpx","permalink":"//D3iddpx","complete":true,"thumbnail_image_url":"http://stage.diveboard.com/map_images/map_1843.jpg","thumbnail_profile_url":null,"guide":null,"shop_id":null,"notes":null,"public_notes":null,"diveshop":null,"current":null,"species":[],"gears":[],"user_gears":[],"dive_gears":[],"date":"2011-10-16","time":"09:40"},{"class":"Dive","flavour":"public","id":31673,"shaken_id":"D3mIIWQ","time_in":"2011-10-17T09:40:00Z","duration":50,"maxdepth":50.0,"user_id":12850,"spot_id":1843,"temp_surface":null,"temp_bottom":null,"privacy":0,"weights":null,"safetystops":null,"divetype":[],"favorite":null,"buddy":[],"visibility":null,"trip_name":null,"water":null,"altitude":0,"fullpermalink":"http://stage.diveboard.com//D3mIIWQ","permalink":"//D3mIIWQ","complete":true,"thumbnail_image_url":"http://stage.diveboard.com/map_images/map_1843.jpg","thumbnail_profile_url":null,"guide":null,"shop_id":null,"notes":null,"public_notes":null,"diveshop":null,"current":null,"species":[],"gears":[],"user_gears":[],"dive_gears":[],"date":"2011-10-17","time":"09:40"}],"user_authentified":true}</td>
  </tr>
</table>


## Updating several objects of the same type at the same time

An array within ‘arg’ can also be used to update several objects of the same type.

<table>
  <tr>
    <td>Example to update 2 different dives at the same time</td>
  </tr>
  <tr>
    <td>curl -s "http://stage.diveboard.com/api/V2/dive"
-F 'auth_token=wtV6sxKrMdXXBV+dVrqhJs936KKrq0TQBw2toWjM+Lk='
-F "apikey=hwkzq4rhw9lq"
-F 'arg=[{"id":31672,"duration": 91},{"id":31673,"maxdepth":51}]'</td>
  </tr>
  <tr>
    <td>{"success":true,"error":[],"result":[{"class":"Dive","flavour":"public","id":31672,"shaken_id":"D3iddpx","time_in":"2011-10-16T09:40:00Z","duration":91,"maxdepth":40.0,"user_id":12850,"spot_id":1843,"temp_surface":null,"temp_bottom":null,"privacy":0,"weights":null,"safetystops":null,"divetype":[],"favorite":null,"buddy":[],"visibility":null,"trip_name":null,"water":null,"altitude":0,"fullpermalink":"http://stage.diveboard.com//D3iddpx","permalink":"//D3iddpx","complete":true,"thumbnail_image_url":"http://stage.diveboard.com/map_images/map_1843.jpg","thumbnail_profile_url":null,"guide":null,"shop_id":null,"notes":null,"public_notes":null,"diveshop":null,"current":null,"species":[],"gears":[],"user_gears":[],"dive_gears":[],"date":"2011-10-16","time":"09:40"},{"class":"Dive","flavour":"public","id":31673,"shaken_id":"D3mIIWQ","time_in":"2011-10-17T09:40:00Z","duration":50,"maxdepth":51.0,"user_id":12850,"spot_id":1843,"temp_surface":null,"temp_bottom":null,"privacy":0,"weights":null,"safetystops":null,"divetype":[],"favorite":null,"buddy":[],"visibility":null,"trip_name":null,"water":null,"altitude":0,"fullpermalink":"http://stage.diveboard.com//D3mIIWQ","permalink":"//D3mIIWQ","complete":true,"thumbnail_image_url":"http://stage.diveboard.com/map_images/map_1843.jpg","thumbnail_profile_url":null,"guide":null,"shop_id":null,"notes":null,"public_notes":null,"diveshop":null,"current":null,"species":[],"gears":[],"user_gears":[],"dive_gears":[],"date":"2011-10-17","time":"09:40"}],"user_authentified":true}</td>
  </tr>
</table>


## Updating recursively several objects at the same time

Now comes the tricky part. When you update an object (e.g. a dive) you can at the same time create or update another object that is referred by this dive. For that, just add the attributes you would like to change along with the ‘id’ attribute that was already provided.

<table>
  <tr>
    <td>Example to update recursively a dive and a user_gear in the same call</td>
  </tr>
  <tr>
    <td>curl -s "http://stage.diveboard.com/api/V2/dive"
-F 'auth_token=wtV6sxKrMdXXBV+dVrqhJs936KKrq0TQBw2toWjM+Lk='
-F "apikey=hwkzq4rhw9lq"
-F 'flavour=private'
-F 'arg={"id":31672, "duration":55, "user_gears":[{"id":2106, "model":"Vyper Air"}]}'</td>
  </tr>
  <tr>
    <td>{"success":true,"error":[],"result":{"class":"Dive","flavour":"private","id":31672,"shaken_id":"D3iddpx","time_in":"2011-10-16T09:40:00Z","duration":55,"maxdepth":40.0,"user_id":12850,"spot_id":1843,"temp_surface":null,"temp_bottom":null,"privacy":0,"weights":null,"safetystops":null,"divetype":[],"favorite":null,"buddy":[],"visibility":null,"trip_name":null,"water":null,"altitude":0,"fullpermalink":"http://stage.diveboard.com//D3iddpx","permalink":"//D3iddpx","complete":true,"thumbnail_image_url":"http://stage.diveboard.com/map_images/map_1843.jpg","thumbnail_profile_url":null,"guide":null,"shop_id":null,"notes":null,"public_notes":null,"diveshop":null,"current":null,"species":[],"gears":[{"class":"UserGear","flavour":"private","category":"Computer","id":2106,"manufacturer":"Suunto","model":"Vyper Air","featured":false,"acquisition":null,"last_revision":null,"reference":null,"auto_feature":"never"}],"user_gears":[{"class":"UserGear","flavour":"private","category":"Computer","id":2106,"manufacturer":"Suunto","model":"Vyper Air","featured":false,"acquisition":null,"last_revision":null,"reference":null,"auto_feature":"never"}],"dive_gears":[],"date":"2011-10-16","time":"09:40","dan_data":null,"dan_data_sent":null,"storage_used":0,"profile_ref":null},"user_authentified":true}</td>
  </tr>
</table>


## Creating recursively objects

This type of call can be very useful to prevent chaining multiple calls. In the example below, instead of calling first the API to create a user_gear and making a second call to assign that user_gear to the dive, only one call can do the trick.

<table>
  <tr>
    <td>Example to create a new user_gear and assigning an existing user_gear to a dive</td>
  </tr>
  <tr>
    <td>curl -s "http://stage.diveboard.com/api/V2/dive"
-F 'auth_token=wtV6sxKrMdXXBV+dVrqhJs936KKrq0TQBw2toWjM+Lk='
-F "apikey=hwkzq4rhw9lq"
-F 'flavour=private'
-F 'arg={"id":31672, "user_gears":[{"id":2106}, {"user_id":12850,"category":"Computer","manufacturer":"Mares","model":"Icon HD"}]}'</td>
  </tr>
  <tr>
    <td>{"success":true,"error":[],"result":{"class":"Dive","flavour":"private","id":31672,"shaken_id":"D3iddpx","time_in":"2011-10-16T09:40:00Z","duration":91,"maxdepth":40.0,"user_id":12850,"spot_id":1843,"temp_surface":null,"temp_bottom":null,"privacy":0,"weights":null,"safetystops":null,"divetype":[],"favorite":null,"buddy":[],"visibility":null,"trip_name":null,"water":null,"altitude":0,"fullpermalink":"http://stage.diveboard.com//D3iddpx","permalink":"//D3iddpx","complete":true,"thumbnail_image_url":"http://stage.diveboard.com/map_images/map_1843.jpg","thumbnail_profile_url":null,"guide":null,"shop_id":null,"notes":null,"public_notes":null,"diveshop":null,"current":null,"species":[],"gears":[{"class":"UserGear","flavour":"private","category":"Computer","id":2106,"manufacturer":"Suunto","model":"Vyper","featured":false,"acquisition":null,"last_revision":null,"reference":null,"auto_feature":"never"},{"class":"UserGear","flavour":"private","category":"Computer","id":2107,"manufacturer":"Mares","model":"Icon HD","featured":false,"acquisition":null,"last_revision":null,"reference":null,"auto_feature":"never"}],"user_gears":[{"class":"UserGear","flavour":"private","category":"Computer","id":2106,"manufacturer":"Suunto","model":"Vyper","featured":false,"acquisition":null,"last_revision":null,"reference":null,"auto_feature":"never"},{"class":"UserGear","flavour":"private","category":"Computer","id":2107,"manufacturer":"Mares","model":"Icon HD","featured":false,"acquisition":null,"last_revision":null,"reference":null,"auto_feature":"never"}],"dive_gears":[],"date":"2011-10-16","time":"09:40","dan_data":null,"dan_data_sent":null,"storage_used":0,"profile_ref":null},"user_authentified":true}</td>
  </tr>
</table>


## Uploading a ZXL or UDCF file

This call will let you upload a profile file in a Diveboard supported format (currently DAN DL7 (aka ZXL or ZXU) and UDCF).

The file will be analyzed and stored and as an output you get a list of the dive profiles present in the file in a digested format as well as their id within the file and the file id itself. This can be used to be bound to a dive.



<table>
  <tr>
    <td>Example to upload a dive profile file (here zxu) and retrieving the file id and the list of dive profiles in the file</td>
  </tr>
  <tr>
    <td>$ curl -F "filename=@carlo.zxu" \
     -F "token=tnNxf1D169xCB32RGgQx3b3EcQavksyP5A3ssgLtAj4=" \
     -F "apikey=7hvvgobT6cnios" \
     http://www.diveboard.com/api/upload_profile</td>
  </tr>
  <tr>
    <td>{"success":"true","nbdives":"13","dive_summary":[{"number":0,"date":"2004-09-07","time":"18:54","duration":8,"max_depth":60.1,"mintemp":25.0,"maxtemp":0.0,"newdive":true},{"number":1,"date":"2004-09-10","time":"17:29","duration":9,"max_depth":10.0,"mintemp":25.0,"maxtemp":0.0,"newdive":true},{"number":2,"date":"2004-09-10","time":"17:40","duration":11,"max_depth":20.1,"mintemp":26.0,"maxtemp":0.0,"newdive":true},{"number":3,"date":"2004-09-10","time":"17:52","duration":11,"max_depth":30.1,"mintemp":26.0,"maxtemp":0.0,"newdive":true},{"number":4,"date":"2004-09-10","time":"18:05","duration":13,"max_depth":40.1,"mintemp":26.0,"maxtemp":0.0,"newdive":true},{"number":5,"date":"2004-09-10","time":"18:19","duration":13,"max_depth":50.0,"mintemp":26.0,"maxtemp":0.0,"newdive":true},{"number":6,"date":"2004-09-10","time":"18:33","duration":23,"max_depth":60.0,"mintemp":26.0,"maxtemp":0.0,"newdive":true},{"number":7,"date":"2004-12-02","time":"17:05","duration":25,"max_depth":50.0,"mintemp":20.0,"maxtemp":0.0,"newdive":true},{"number":8,"date":"2005-09-25","time":"11:02","duration":52,"max_depth":33.2,"mintemp":17.0,"maxtemp":0.0,"newdive":true},{"number":9,"date":"2006-01-15","time":"13:36","duration":51,"max_depth":38.0,"mintemp":12.0,"maxtemp":0.0,"newdive":true},{"number":10,"date":"2006-07-16","time":"12:10","duration":51,"max_depth":33.0,"mintemp":18.0,"maxtemp":0.0,"newdive":true},{"number":11,"date":"2006-07-16","time":"14:41","duration":63,"max_depth":29.1,"mintemp":19.0,"maxtemp":0.0,"newdive":true},{"number":12,"date":"2006-10-15","time":"12:33","duration":73,"max_depth":26.1,"mintemp":20.0,"maxtemp":0.0,"newdive":true}],"fileid":1333}</td>
  </tr>
</table>


## Error catching

$ curl http://www.diveboard.com/api/V2/user

{"success":false,"error":[{"error":"What do you want me to do ? you should specify 'arg'","object":null}]}

$ curl "http://www.diveboard.com/api/V2/user?arg=%7Bid:48,nickname:'coucou'%7D&auth_token=ip4rHSSD9/diOWR3szonh7ikbhl0k9g/UgMSTBfjb00=&apikey=xxXXX6XXX6XxxxX6XXXX"

{"success":true,"error":[{"error":"Forbidden","object":{"id":48,"nickname":"coucou"}}],"result":{"class":"User","flavour":"public","id":48,"vanity_url":"pascal","qualifications":{"featured":[{"org":"CMAS","title":"2 stars diver","date":"2011-07-26"},{"org":"PADI","title":"Advanced Open Water","date":"2011-07-25"},{"org":"CMAS","title":"Nitrox","date":"2011-10-17"}],"other":[{"org":"Other","title":"Cayman Island Lionfish Culling License","date":"2011-11-08"},{"org":"CMAS","title":"1 star","date":"2007-06-01"}]},"picture":"http://www.diveboard.com/user_images/48.png","picture_small":"http://www.diveboard.com/user_images/48.png","picture_large":"http://www.diveboard.com/user_images/48.png","full_permalink":"http://www.diveboard.com/pascal","total_nb_dives":66,"public_nb_dives":29,"public_dive_ids":["728","33","34","30","29","28","27","26","25","24","23","22","10305","555","1850","1851","2434","2435","2436","2437","2438","2439","2442","2443","2532","2533","2569","2570","5632"],"nickname":"Pascal"}}

$ curl "http://www.diveboard.com/api/V2/dive?arg=%7Bid:2434, duration:123%7D&auth_token=ip4rHSSD9/diOWR3szonh7ikbhl0k9g/UgMSTBfjb00=&apikey=xxXXX6XXX6XxxxX6XXXX"

{"success":true,"error":[{"error":"Forbidden","object":{"id":2434,"**duration**":**123**}}],"result":{"class":"Dive","flavour":"public","id":2434,"time_in":"2011-10-16T09:40:00Z","duration":53,"maxdepth":"20.1","user_id":48,"spot_id":1843,"temp_surface":20.0,"temp_bottom":19.0,"privacy":0,"weights":null,"safetystops":"[]","divetype":["recreational","Autonomy"],"favorite":null,"buddy":[],"visibility":null,"trip_name":"Nitrox training - Marseilles","water":null,"altitude":0,"fullpermalink":"http://www.diveboard.com/pascal/2434","complete":true,"thumbnail_image_url":"http://www.diveboard.com/map_images/map_1843.jpg","thumbnail_profile_url":"http://www.diveboard.com/pascal/2434/profile.png?g=small_or&u=m","species":[],"guide":"","shop_id":812,"notes":null,"public_notes":null,"diveshop":{"name":"ATOLL - DEEP SUB","url":"http://www.atollplongee.com","guide":"","id":812},"gears":[],"user_gears":[],"dive_gears":[],"date":"2011-10-16","time":"09:40"}}

# Objects

### USER

<table>
  <tr>
    <td>Parameter</td>
    <td>R
E
A
D</td>
    <td>W
R
I
T
E</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Present in flavours</td>
    <td>Comments for read</td>
    <td>Comments for write</td>
  </tr>
  <tr>
    <td>id</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>INTEGER</td>
    <td>all</td>
    <td>the id of the dive to update
if absent, a new dive will be created</td>
    <td></td>
  </tr>
  <tr>
    <td>shaken_id</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td>this attribute is a obfuscated version of the id. It will always be the same for a given object.</td>
    <td></td>
  </tr>
  <tr>
    <td>vanity_url</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>qualifications</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>QUALIFICATION Object</td>
    <td>all</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>picture</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>URL</td>
    <td>all</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>picture_small</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>URL</td>
    <td>all</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>picture_large</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>URL</td>
    <td>all</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>full_permalink</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>URL</td>
    <td>all</td>
    <td>Full direct link to the user’s logbook on Diveboard</td>
    <td></td>
  </tr>
  <tr>
    <td>permalink</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>URL</td>
    <td>all</td>
    <td>Relative path to the logbook (e.g. "/toto")</td>
    <td></td>
  </tr>
  <tr>
    <td>total_nb_dives</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>INTEGER</td>
    <td>all</td>
    <td>Number of dives including external dives</td>
    <td></td>
  </tr>
  <tr>
    <td>public_nb_dives</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>INTEGER</td>
    <td>all</td>
    <td>Number of public dives</td>
    <td></td>
  </tr>
  <tr>
    <td>public_dive_ids</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>ARRAY of INTEGER</td>
    <td>all</td>
    <td>List of all the public dive IDs</td>
    <td></td>
  </tr>
  <tr>
    <td>location</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td>2 letters country code of the user in lowercase</td>
    <td></td>
  </tr>
  <tr>
    <td>nickname</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td>Main name displayed all over Diveboard</td>
    <td></td>
  </tr>
  <tr>
    <td>auto_public</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>BOOLEAN</td>
    <td>all</td>
    <td>Private data, indicates whether the user wants to set the dive as public by default</td>
    <td></td>
  </tr>
  <tr>
    <td>dan_data</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>HASH</td>
    <td>private</td>
    <td>Private data used to send DAN forms
DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>storage_used</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>HASH</td>
    <td>private</td>
    <td>Detail of the storage used on Diveboard (for pictures mainly)
DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>quota_type</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>STRING</td>
    <td>private</td>
    <td>Storage limit type
DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>quota_limit</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>INTEGER</td>
    <td>private</td>
    <td>Storage limit
DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>all_dive_ids</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>ARRAY of INTEGER</td>
    <td>private</td>
    <td>List of all dives for this user, including private dives</td>
    <td></td>
  </tr>
  <tr>
    <td>pict</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>BOOLEAN</td>
    <td>private</td>
    <td>Does the user have a custom picture
DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>advertisements</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>ARRAY</td>
    <td>private</td>
    <td>DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>ad_album_id</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>INTEGER</td>
    <td>private</td>
    <td>DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>user_gears</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>ARRAY of USER_GEAR objects</td>
    <td>private</td>
    <td>The gear owned by the user that will be used on various dives</td>
    <td></td>
  </tr>
  <tr>
    <td>about</td>
    <td></td>
    <td>X</td>
    <td></td>
    <td></td>
    <td></td>
    <td>DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>email</td>
    <td></td>
    <td>X</td>
    <td></td>
    <td></td>
    <td></td>
    <td>DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>contact_email</td>
    <td></td>
    <td>X</td>
    <td></td>
    <td></td>
    <td></td>
    <td>DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>location</td>
    <td></td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>all</td>
    <td>Country indicator</td>
    <td></td>
  </tr>
  <tr>
    <td>settings</td>
    <td></td>
    <td>X</td>
    <td></td>
    <td></td>
    <td></td>
    <td>DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>total_ext_dives</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>INTEGER</td>
    <td>private</td>
    <td>Number of dives not on Diveboard, so that total_nb_dives reflects the real number of dives of the user</td>
    <td></td>
  </tr>
  <tr>
    <td>dives</td>
    <td></td>
    <td>X</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>wallet_pictures</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>ARRAY of PICTURE objects</td>
    <td>private</td>
    <td>gives an array of Picture objects in user wallet </td>
    <td></td>
  </tr>
  <tr>
    <td>wallet_pictures_id</td>
    <td></td>
    <td>X</td>
    <td></td>
    <td>ARRAY OF INTEGER</td>
    <td>private</td>
    <td>Sets the array of ids of pictures in user wallet</td>
    <td></td>
  </tr>
</table>


### QUALIFICATION OBJECT

<table>
  <tr>
    <td>Parameter</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Comments</td>
  </tr>
  <tr>
    <td>featured</td>
    <td>NO</td>
    <td>ARRAY OF QUALIF_DETAIL</td>
    <td>List of qualifications that will appear on the profile</td>
  </tr>
  <tr>
    <td>other</td>
    <td>NO</td>
    <td>ARRAY OF QUALIF_DETAIL</td>
    <td>List of qualifications that will only appear on the user’s logbook cover</td>
  </tr>
</table>


### QUALIF_DETAIL Object

<table>
  <tr>
    <td>Parameter</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Comments</td>
  </tr>
  <tr>
    <td>org</td>
    <td>NO</td>
    <td>STRING</td>
    <td>Certification Organisation </td>
  </tr>
  <tr>
    <td>title</td>
    <td>NO</td>
    <td>STRING</td>
    <td>Title of the certification</td>
  </tr>
  <tr>
    <td>date</td>
    <td>NO</td>
    <td>STRING
YYYY-MM-DD</td>
    <td>Date of certification</td>
  </tr>
</table>


### EXTERNAL USER

<table>
  <tr>
    <td>Parameter</td>
    <td>R
E
A
D</td>
    <td>W
R
I
T
E</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Present in flavours</td>
    <td>Comments for read</td>
    <td>Comments for write</td>
  </tr>
  <tr>
    <td>id</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>INTEGER</td>
    <td>all</td>
    <td>the id of the external user object to update
if absent, a new object will be created</td>
    <td></td>
  </tr>
  <tr>
    <td>nickname</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>Nickname of the person</td>
    <td></td>
  </tr>
  <tr>
    <td>picture</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td>URL</td>
    <td>all</td>
    <td>standard version of the user’s picture if available</td>
    <td>for setting this attribute for non-facebook users, use the attribute picturl</td>
  </tr>
  <tr>
    <td>picture_small</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td>URL</td>
    <td>all</td>
    <td>small version of the user’s picture  if available</td>
    <td>for setting this attribute for non-facebook users, use the attribute picturl</td>
  </tr>
  <tr>
    <td>picture_large</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td>URL</td>
    <td>all</td>
    <td>large version of the user’s picture if available</td>
    <td>for setting this attribute for non-facebook users, use the attribute picturl</td>
  </tr>
  <tr>
    <td>picturl</td>
    <td></td>
    <td>X</td>
    <td>X</td>
    <td>URL</td>
    <td></td>
    <td></td>
    <td>permanent URL to the picture of the user (external url possible, should not be used for facebook users)</td>
  </tr>
  <tr>
    <td>fb_id</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>private</td>
    <td>Facebook ID</td>
    <td></td>
  </tr>
  <tr>
    <td>email</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>TEXT</td>
    <td>private</td>
    <td>User’s email address</td>
    <td></td>
  </tr>
</table>


### DIVE

<table>
  <tr>
    <td>Parameter</td>
    <td>R
E
A
D</td>
    <td>W
R
I
T
E</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Present in flavours</td>
    <td>Comments for read</td>
    <td>Comments for write</td>
  </tr>
  <tr>
    <td>id</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>INTEGER</td>
    <td>all</td>
    <td>the id of the dive to update
if absent, a new dive will be created</td>
    <td></td>
  </tr>
  <tr>
    <td>shaken_id</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td>this attribute is a obfuscated version of the id. It will always be the same for a given object.</td>
    <td></td>
  </tr>
  <tr>
    <td>user_id</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>INTEGER</td>
    <td>all</td>
    <td>id of the dive’s owner</td>
    <td>id of the dive’s owner</td>
  </tr>
  <tr>
    <td>spot</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>SPOT object</td>
    <td>mobile</td>
    <td></td>
    <td>The spot tied to this dive - either an existing spot or a new one
if no spot is used, MUST use the spot id 1 (sorry) {id = 1}</td>
  </tr>
  <tr>
    <td>spot_id</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>INTEGER</td>
    <td>all</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>time_in</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>DATETIME</td>
    <td>all</td>
    <td>"YYYY-MM-DD HH:MM:SS" when diver entered the sea in local time</td>
    <td>"YYYY-MM-DD HH:MM:SS" when diver entered the sea in local time</td>
  </tr>
  <tr>
    <td>maxdepth</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>FLOAT</td>
    <td>all</td>
    <td>in meters</td>
    <td>in meters</td>
  </tr>
  <tr>
    <td>duration</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>INTEGER</td>
    <td>all</td>
    <td>in minutes</td>
    <td>in minutes</td>
  </tr>
  <tr>
    <td>temp_surface</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>FLOAT</td>
    <td>all</td>
    <td>Temperature of the water at the surface in celsius</td>
    <td>Temperature of the water at the surface in celsius</td>
  </tr>
  <tr>
    <td>temp_bottom</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>FLOAT</td>
    <td>all</td>
    <td>Temperature of the water at the bottom in celsius</td>
    <td>Temperature of the water at the bottom in celsius</td>
  </tr>
  <tr>
    <td>privacy</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>1 = dive is private, 0 = dive is public</td>
    <td>1 = dive is private, 0 = dive is public</td>
  </tr>
  <tr>
    <td>weights</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>FLOAT</td>
    <td>all</td>
    <td>in kg</td>
    <td>in kg</td>
  </tr>
  <tr>
    <td>safetystops</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>JSON of ARRAY of SAFETYSTOP</td>
    <td>all</td>
    <td>the list of safety stops
e.g: [["6","3"],["3","3"]]</td>
    <td>the list of safety stops</td>
  </tr>
  <tr>
    <td>divetype</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>ARRAY of STRINGS</td>
    <td>all</td>
    <td>the list of the dive types done - strings are free fields
e.g: ["training","deep dive","wreck"]</td>
    <td>the list of the dive types done - strings are free fields
e.g: ["training","deep dive","wreck"]</td>
  </tr>
  <tr>
    <td>favorite</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>BOOLEAN</td>
    <td>all</td>
    <td>false or null = dive is not in the favorite set
true= dive is in the favorite set</td>
    <td>false = dive is not in the favorite set
true= dive is in the favorite set</td>
  </tr>
  <tr>
    <td>buddies</td>
    <td></td>
    <td>X</td>
    <td>X</td>
    <td>ARRAY of USER and/or EXTERNAL_USER objects</td>
    <td>all</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>buddies</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>ARRAY of BUDDY objects</td>
    <td>all</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>visibility</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>string taken in : 'bad','average','good','excellent'</td>
    <td>string taken in : 'bad','average','good','excellent'</td>
  </tr>
  <tr>
    <td>trip_name</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>Maximum 255 characters, free field</td>
    <td>Maximum 255 characters, free field</td>
  </tr>
  <tr>
    <td>water</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>string taken in : 'salt','fresh'</td>
    <td>string taken in : 'salt','fresh'</td>
  </tr>
  <tr>
    <td>current</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>string taken in : 'none','light','medium','strong','extreme'</td>
    <td>string taken in : 'none','light','medium','strong','extreme'</td>
  </tr>
  <tr>
    <td>altitude</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>FLOAT</td>
    <td>all</td>
    <td>in meters</td>
    <td>in meters</td>
  </tr>
  <tr>
    <td>fullpermalink</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>URL</td>
    <td>all</td>
    <td>direct full url to the dive (including http://xxx.diveboard.com/....)</td>
    <td></td>
  </tr>
  <tr>
    <td>permalink</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td>DEPRECATED
path to the dive (without the leading http://xxx.diveboard.com)</td>
    <td></td>
  </tr>
  <tr>
    <td>complete</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>BOOL</td>
    <td>all</td>
    <td>true if the dive could be made public (i.e. has at least a spot, max depth & duration)</td>
    <td></td>
  </tr>
  <tr>
    <td>thumbnail_image_url</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td>url to a square thumbnail image representing the dive (128x128)</td>
    <td></td>
  </tr>
  <tr>
    <td>thumbnail_profile_url</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>url to a thumbnail representing the dive profile data graph</td>
    <td></td>
  </tr>
  <tr>
    <td>species</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>ARRAY of SPECIES</td>
    <td>all</td>
    <td>array of the species spotted during the dive - only "s-XXXXX" (c- gets replaced by its s-) species => [{:id => "s-1234"}, {:id => "s-2345"}]
</td>
    <td>array of the species spotted during the dive as scientific name "s-XXXX" or common name "c-XXXX" species => [{:id => "s-1234"}, {:id => "s-2345"}]
</td>
  </tr>
  <tr>
    <td>guide</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>name of the guide</td>
    <td>name of the guide</td>
  </tr>
  <tr>
    <td>shop</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>SHOP object</td>
    <td>all</td>
    <td></td>
    <td>the dive shop the user dived with, when the shop already exists in Diveboard database</td>
  </tr>
  <tr>
    <td>shop_id</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>id of the dive shop used in that dive</td>
    <td></td>
  </tr>
  <tr>
    <td>diveshop</td>
    <td></td>
    <td>X</td>
    <td>X</td>
    <td>HASH</td>
    <td></td>
    <td></td>
    <td>DEPRECATED
A Hash containing the following key, to enable a free fill in when a diveshop does not exists in Diveboard database :
- name : name of the shop
- url : url of the shop
- country : country code
- town : town name</td>
  </tr>
  <tr>
    <td>diveshop</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td>HASH</td>
    <td>all</td>
    <td>DEPRECATED
A Hash containing some of the following key. It is constructed based on the ‘diveshop’ value, and overwritten with the values of ‘shop’ and ‘guide’ if available.

At least one of the two following attributes are present :
- name : name of the shop
- guide : name of the guide

The following attributes may be present :
- url : url of the shop
- country : country code
- town : town name</td>
    <td></td>
  </tr>
  <tr>
    <td>notes</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>notes for the dive (free field)
readable only by owner</td>
    <td>notes for the dive (free field)</td>
  </tr>
  <tr>
    <td>public_notes</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>notes for the dive (free field)</td>
    <td>notes for the dive (free field)</td>
  </tr>
  <tr>
    <td>tanks</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>ARRAY of TANK object</td>
    <td>private</td>
    <td>Tanks used during the dive</td>
    <td></td>
  </tr>
  <tr>
    <td>gears</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td></td>
    <td>all</td>
    <td>Gear used for the dive (Both user_gears and dive_gears)</td>
    <td></td>
  </tr>
  <tr>
    <td>user_gears</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>ARRAY of USER_GEAR object</td>
    <td>all</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>dive_gears</td>
    <td></td>
    <td></td>
    <td></td>
    <td>ARRAY of DIVE_GEAR object</td>
    <td>all</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>date</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td>DATE</td>
    <td>all</td>
    <td>Date of the dive</td>
    <td>YYYY-MM-DD</td>
  </tr>
  <tr>
    <td>time</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td>TIME</td>
    <td>all</td>
    <td>Time of the dive</td>
    <td>HH:MM 24-hr, "local" timezone to the spot</td>
  </tr>
  <tr>
    <td>dan_data</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>DAN Object</td>
    <td>private</td>
    <td>DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>dan_data_sent</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td></td>
    <td>private</td>
    <td>DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>storage_used</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td>private</td>
    <td>DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>profile_ref</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>private</td>
    <td>Profile reference for UDCF uploads</td>
    <td></td>
  </tr>
  <tr>
    <td>pictures</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>mobile</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>number</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>Number of the dive in the logbook</td>
    <td></td>
  </tr>
  <tr>
    <td>send_to_dan</td>
    <td></td>
    <td>X</td>
    <td></td>
    <td></td>
    <td></td>
    <td>DO NOT USE</td>
    <td></td>
  </tr>
  <tr>
    <td>raw_profile</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>ARRAY of PROFILE_SAMPLE objects</td>
    <td>public_with_profile</td>
    <td>Dive profile data</td>
    <td></td>
  </tr>
  <tr>
    <td>featured_picture</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td></td>
    <td>mobile</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>featured_gears</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td></td>
    <td>mobile</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>other_gears</td>
    <td></td>
    <td></td>
    <td></td>
    <td></td>
    <td>mobile</td>
    <td></td>
    <td></td>
  </tr>
</table>


### SAFETYSTOP

Each safety stop is stored as an array of the depth and the duration.

<table>
  <tr>
    <td>Position in Array</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>0</td>
    <td>INTEGER</td>
    <td>MANDATORY</td>
    <td>depth in meters</td>
  </tr>
  <tr>
    <td>1</td>
    <td>INTEGER</td>
    <td>MANDATORY</td>
    <td>time in minutes</td>
  </tr>
</table>


example : [5,3] => 5 meters, 3 minutes stop

### PROFILE_SAMPLE

<table>
  <tr>
    <td>Parameter</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Comments</td>
  </tr>
  <tr>
    <td>seconds</td>
    <td>NO</td>
    <td>INTEGER</td>
    <td>time of the sample since the beginning of the dive</td>
  </tr>
  <tr>
    <td>depth</td>
    <td>YES</td>
    <td>FLOAT</td>
    <td>Unit: meters</td>
  </tr>
  <tr>
    <td>current_water_temperature</td>
    <td>YES</td>
    <td>FLOAT</td>
    <td>Unit: celsius degrees</td>
  </tr>
  <tr>
    <td>main_cylinder_pressure</td>
    <td>YES</td>
    <td>FLOAT</td>
    <td>Unit: bar</td>
  </tr>
  <tr>
    <td>heart_beats</td>
    <td>YES</td>
    <td>FLOAT</td>
    <td>Unit: beat per minutes</td>
  </tr>
  <tr>
    <td>deco_violation</td>
    <td>NO</td>
    <td>BOOLEAN</td>
    <td>defaults to false when absent, indicates when the diver has not respected his decompression procedure</td>
  </tr>
  <tr>
    <td>deco_start</td>
    <td>NO</td>
    <td>BOOLEAN</td>
    <td>defaults to false when absent,indicates when the dive started to have decompression stop (on top of the 3min for safety)</td>
  </tr>
  <tr>
    <td>ascent_violation</td>
    <td>NO</td>
    <td>BOOLEAN</td>
    <td>defaults to false when absent,indicates when the diver went up too fast</td>
  </tr>
  <tr>
    <td>bookmark</td>
    <td>NO</td>
    <td>BOOLEAN</td>
    <td>defaults to false when absent,indicates then the diver has logged a bookmark during the dive</td>
  </tr>
  <tr>
    <td>surface_event</td>
    <td>NO</td>
    <td>BOOLEAN</td>
    <td>defaults to false when absent,indicates when the diver has reached the surface</td>
  </tr>
</table>


### BUDDY

<table>
  <tr>
    <td>Parameter</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Comments</td>
  </tr>
  <tr>
    <td>name</td>
    <td></td>
    <td>STRING</td>
    <td>Name of your buddy - free text</td>
  </tr>
  <tr>
    <td>db_id</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>id of the buddy on diveboard</td>
  </tr>
  <tr>
    <td>fb_id</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>facebook id of the buddy</td>
  </tr>
  <tr>
    <td>email</td>
    <td>X</td>
    <td>STRING</td>
    <td>email of your buddy</td>
  </tr>
  <tr>
    <td>picturl</td>
    <td>X</td>
    <td>STRING</td>
    <td>url to a picture of your buddy</td>
  </tr>
</table>


### DIVE_GEAR

<table>
  <tr>
    <td>Parameter</td>
    <td>R</td>
    <td>W</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Present in flavours</td>
    <td>Comments for read</td>
    <td>Comments for write</td>
  </tr>
  <tr>
    <td>id</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>the dive_gear object id</td>
    <td>the dive_gear object id</td>
  </tr>
  <tr>
    <td>category</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>in 'BCD','Boots','Computer','Compass','Camera','Cylinder','Dive skin','Dry suit','Fins','Gloves','Hood','Knife','Light','Lift bag','Mask','Other','Rebreather','Regulator','Scooter','Wet suit'</td>
    <td>in 'BCD','Boots','Computer','Compass','Camera','Cylinder','Dive skin','Dry suit','Fins','Gloves','Hood','Knife','Light','Lift bag','Mask','Other','Rebreather','Regulator','Scooter','Wet suit'</td>
  </tr>
  <tr>
    <td>manufacturer</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>Manufacturer’s name</td>
    <td>Manufacturer’s name</td>
  </tr>
  <tr>
    <td>model</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>Model’s name</td>
    <td>Model’s name</td>
  </tr>
  <tr>
    <td>featured</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>BOOL</td>
    <td>all</td>
    <td>true if the gear is featured in the dive</td>
    <td>true if the gear is featured in the dive</td>
  </tr>
</table>


### USER_GEAR

<table>
  <tr>
    <td>Parameter</td>
    <td>R</td>
    <td>W</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Present in flavours</td>
    <td>Comments for read</td>
    <td>Comments for write</td>
  </tr>
  <tr>
    <td>id</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>the dive_gear object id</td>
    <td>the dive_gear object id</td>
  </tr>
  <tr>
    <td>category</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>in 'BCD','Boots','Computer','Compass','Camera','Cylinder','Dive skin','Dry suit','Fins','Gloves','Hood','Knife','Light','Lift bag','Mask','Other','Rebreather','Regulator','Scooter','Wet suit'</td>
    <td>in 'BCD','Boots','Computer','Compass','Camera','Cylinder','Dive skin','Dry suit','Fins','Gloves','Hood','Knife','Light','Lift bag','Mask','Other','Rebreather','Regulator','Scooter','Wet suit'</td>
  </tr>
  <tr>
    <td>manufacturer</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>Manufacturer’s name</td>
    <td>Manufacturer’s name</td>
  </tr>
  <tr>
    <td>model</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>Model’s name</td>
    <td>Model’s name</td>
  </tr>
  <tr>
    <td>featured</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>BOOL</td>
    <td>all</td>
    <td>true if the gear is featured in the dive</td>
    <td>true if the gear is featured in the dive</td>
  </tr>
  <tr>
    <td>acquisition</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>DATE</td>
    <td>private</td>
    <td>YYYY-MM-DD of acquisition</td>
    <td>YYYY-MM-DD of acquisition</td>
  </tr>
  <tr>
    <td>auto_feature</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>private</td>
    <td>defines in which section the gear will go : select in  'never','featured','other'</td>
    <td>defines in which section the gear will go : select in  'never','featured','other'</td>
  </tr>
  <tr>
    <td>last_revision</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>DATE</td>
    <td>private</td>
    <td>YYYY-MM-DD of last revision</td>
    <td>YYYY-MM-DD of last revision</td>
  </tr>
  <tr>
    <td>reference</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>private</td>
    <td>free field with reference number</td>
    <td>free field with reference number</td>
  </tr>
</table>


### SPECIES

<table>
  <tr>
    <td>Parameter</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Comments</td>
  </tr>
  <tr>
    <td>id</td>
    <td></td>
    <td>STRING</td>
    <td>Id of the species either "s-12435413" (scientific name) or "c-214324" (common name)</td>
  </tr>
  <tr>
    <td>name</td>
    <td>X</td>
    <td>STRING</td>
    <td>Preferred common name of the species</td>
  </tr>
  <tr>
    <td>sname</td>
    <td></td>
    <td>STRING</td>
    <td>Scientific name of the species</td>
  </tr>
  <tr>
    <td>link</td>
    <td>X</td>
    <td>STRING</td>
    <td>Link to species information page ( EOL.org )</td>
  </tr>
  <tr>
    <td>thumbnail_href</td>
    <td>X</td>
    <td>STRING</td>
    <td>url to a thumbnail of the fish picture</td>
  </tr>
  <tr>
    <td>picture</td>
    <td>X</td>
    <td>STRING</td>
    <td>url to a picture of the species</td>
  </tr>
</table>


### SHOP

<table>
  <tr>
    <td>Parameter</td>
    <td>R</td>
    <td>W</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Present in flavours</td>
    <td>Comments for read</td>
    <td>Comments for write</td>
  </tr>
  <tr>
    <td>id</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>the id of the dive shop to update
if absent, a new dive will be created</td>
    <td>the id of the dive shop to update
if absent, a new dive will be created</td>
  </tr>
  <tr>
    <td>name</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>the name of the dive shop</td>
    <td>the name of the dive shop</td>
  </tr>
  <tr>
    <td>lat</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>FLOAT</td>
    <td>all</td>
    <td>Latitude of the dive shop</td>
    <td>Latitude of the dive shop</td>
  </tr>
  <tr>
    <td>lng</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>FLOAT</td>
    <td>all</td>
    <td>Longitude of the dive shop</td>
    <td>Longitude of the dive shop</td>
  </tr>
  <tr>
    <td>address</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>the dive shop address</td>
    <td>the dive shop address</td>
  </tr>
  <tr>
    <td>email</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>contact email for the dive shop</td>
    <td>contact email for the dive shop</td>
  </tr>
  <tr>
    <td>web</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>url of the dive shop (including the leading http://)</td>
    <td>url of the dive shop (including the leading http://)</td>
  </tr>
  <tr>
    <td>phone</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>dive shop’s phone</td>
    <td>dive shop’s phone</td>
  </tr>
  <tr>
    <td>logo_url</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>url to the logo of the dive shop (including the leading http://)</td>
    <td>url to the logo of the dive shop (including the leading http://)</td>
  </tr>
  <tr>
    <td>dive_ids</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>ARRAY of (DIVE object).id</td>
    <td>search_light</td>
    <td>Array of ids of dives done in that spot</td>
    <td>Array of ids of dives done in that spot</td>
  </tr>
  <tr>
    <td>dive_count</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>INTEGER</td>
    <td>search_light</td>
    <td>Number of dives </td>
    <td>Number of dives done in this spot</td>
  </tr>
</table>


### Spot

<table>
  <tr>
    <td>Parameter</td>
    <td>R</td>
    <td>W</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Present in flavours</td>
    <td>Comments for read</td>
    <td>Comments for write</td>
  </tr>
  <tr>
    <td>id</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>the id of the spot to update
if absent, a new dive will be created</td>
    <td>the id of the spot to update
if absent, a new dive will be created</td>
  </tr>
  <tr>
    <td>shaken_id</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td></td>
    <td></td>
  </tr>
  <tr>
    <td>name</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td>the name of the spot</td>
    <td>the name of the spot</td>
  </tr>
  <tr>
    <td>lat</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>FLOAT</td>
    <td>all</td>
    <td>Latitude of the dive shop</td>
    <td>Latitude of the dive shop</td>
  </tr>
  <tr>
    <td>lng</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>FLOAT</td>
    <td>all</td>
    <td>Longitude of the dive shop</td>
    <td>Longitude of the dive shop</td>
  </tr>
  <tr>
    <td>zoom</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>INTEGER</td>
    <td>all</td>
    <td>preferred zoom level for a nice render in a map (7-> 12)</td>
    <td>preferred zoom level for a nice render in a map (7-> 12)</td>
  </tr>
  <tr>
    <td>location</td>
    <td></td>
    <td>X</td>
    <td></td>
    <td>OBJECT</td>
    <td>all</td>
    <td>Where the spot is located</td>
    <td></td>
  </tr>
  <tr>
    <td>location_id</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>INTEGER</td>
    <td>all</td>
    <td></td>
    <td>Where the spot is located</td>
  </tr>
  <tr>
    <td>region</td>
    <td></td>
    <td>X</td>
    <td>X</td>
    <td>OBJECT</td>
    <td>all</td>
    <td>Body of water where the spot is located</td>
    <td></td>
  </tr>
  <tr>
    <td>region_id</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td>INTEGER</td>
    <td></td>
    <td></td>
    <td>Body of water where the spot is located</td>
  </tr>
  <tr>
    <td>country_id</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>INTEGER</td>
    <td>all</td>
    <td>Country where the spot is located</td>
    <td>Country where the spot is located</td>
  </tr>
  <tr>
    <td>private_user_id</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>user id of the owner of the spot - is set spot is "private" i.e. not moderated</td>
    <td>user id of the owner of the spot - is set spot is "private" i.e. not moderated</td>
  </tr>
  <tr>
    <td>country_code</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td></td>
    <td>ISO Country code (2 letters)
E.g. FR for France, GB for United Kingdom, MT for Malta </td>
  </tr>
  <tr>
    <td>country_name</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td>Full country name</td>
    <td></td>
  </tr>
  <tr>
    <td>country_flag_big</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>URL</td>
    <td>all</td>
    <td>URL to the big flag image</td>
    <td></td>
  </tr>
  <tr>
    <td>country_flag_small</td>
    <td>X</td>
    <td></td>
    <td></td>
    <td>URL</td>
    <td>all</td>
    <td>URL to the small flag image</td>
    <td></td>
  </tr>
</table>


### LOCATION

A location is the area where a spot is located, mainly a big city, or a zone i.e. Sidney, NSW or San-Franciso...

<table>
  <tr>
    <td>Parameter</td>
    <td>R</td>
    <td>W</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Present in flavours</td>
    <td>Comments for read</td>
    <td>Comments for write</td>
  </tr>
  <tr>
    <td>id</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>the id of the location to update
if absent, a new dive will be created</td>
    <td>location can NOT be updated</td>
  </tr>
  <tr>
    <td>name</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td>the name of the location</td>
    <td>the name of the location</td>
  </tr>
  <tr>
    <td>country_id</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>INTEGER</td>
    <td>all</td>
    <td>country_id where location is</td>
    <td>country_id where location is</td>
  </tr>
</table>


**REGION**

A location is the body of water where a spot is located, Atlantic Ocean, Mediterranean Sea, Pacific Ocean...

<table>
  <tr>
    <td>Parameter</td>
    <td>R</td>
    <td>W</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Present in flavours</td>
    <td>Comments for read</td>
    <td>Comments for write</td>
  </tr>
  <tr>
    <td>id</td>
    <td>X</td>
    <td></td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>the id of the location to update
if absent, a new dive will be created</td>
    <td>location can NOT be updated</td>
  </tr>
  <tr>
    <td>name</td>
    <td>X</td>
    <td>X</td>
    <td></td>
    <td>STRING</td>
    <td>all</td>
    <td>the name of the location</td>
    <td>the name of the location</td>
  </tr>
</table>


### TANKS

<table>
  <tr>
    <td>Parameter</td>
    <td>R</td>
    <td>W</td>
    <td>Can be nil</td>
    <td>Type/Format</td>
    <td>Present in flavours</td>
    <td>Comments for read</td>
    <td>Comments for write</td>
  </tr>
  <tr>
    <td>id</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>Tank id</td>
    <td>Tank id</td>
  </tr>
  <tr>
    <td>material</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>string in 'aluminium','steel'</td>
    <td>string in 'aluminium','steel'</td>
  </tr>
  <tr>
    <td>gas</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>STRING</td>
    <td>all</td>
    <td>string in 'air','EANx32','EANx36','EANx40','custom'</td>
    <td>string in 'air','EANx32','EANx36','EANx40','custom'</td>
  </tr>
  <tr>
    <td>volume</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>FLOAT</td>
    <td>all</td>
    <td>Volume of the tank in L</td>
    <td>Volume of the tank in L</td>
  </tr>
  <tr>
    <td>multitank</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>number of such tanks (1 or 2 for dual tanks)</td>
    <td>number of such tanks (1 or 2 for dual tanks)</td>
  </tr>
  <tr>
    <td>o2</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>percentage of o2 in gaz 0-100
only used if gas=’custom’</td>
    <td>percentage of o2 in gaz 0-100
only used if gas=’custom’</td>
  </tr>
  <tr>
    <td>n2</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>percentage of n2 in gaz 0-100
only used if gas=’custom’</td>
    <td>percentage of n2 in gaz 0-100
only used if gas=’custom’</td>
  </tr>
  <tr>
    <td>he</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>percentage of he in gaz 0-100
only used if gas=’custom’</td>
    <td>percentage of he in gaz 0-100
only used if gas=’custom’</td>
  </tr>
  <tr>
    <td>time_start</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>INTEGER</td>
    <td>all</td>
    <td>time in minutes from the start of the dive when diver switched to this tank</td>
    <td>time in minutes from the start of the dive when diver switched to this tank</td>
  </tr>
  <tr>
    <td>p_start</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>FLOAT</td>
    <td>all</td>
    <td>Initial pressure in bottle in bar</td>
    <td>Initial pressure in bottle in bar</td>
  </tr>
  <tr>
    <td>p_end</td>
    <td>X</td>
    <td>X</td>
    <td>X</td>
    <td>FLOAT</td>
    <td>all</td>
    <td>Final pressure in bottle in bar</td>
    <td>Final pressure in bottle in bar</td>
  </tr>
</table>


### UNITS

The attribute "Units" is deprecated. To get or set the preferred units of a user, use the preferred_units attribute.

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>distance</td>
    <td>STRING
"m" or “ft”</td>
    <td>M</td>
    <td>N</td>
    <td></td>
  </tr>
  <tr>
    <td>weight</td>
    <td>STRING
“kg” or “lbs”</td>
    <td>M</td>
    <td>Y</td>
    <td></td>
  </tr>
  <tr>
    <td>temperature</td>
    <td>STRING
“C” or “F”</td>
    <td>M</td>
    <td>Y</td>
    <td></td>
  </tr>
  <tr>
    <td>pressure</td>
    <td>“bar” or “psi”</td>
    <td>M</td>
    <td>Y</td>
    <td></td>
  </tr>
</table>


### Object ERROR

<table>
  <tr>
    <td>Name</td>
    <td>Type / Format</td>
    <td>Mandatory/Optional</td>
    <td>Null?</td>
    <td>Description</td>
  </tr>
  <tr>
    <td>error</td>
    <td>STRING</td>
    <td>M</td>
    <td>N</td>
    <td>technical error message</td>
  </tr>
  <tr>
    <td>object</td>
    <td>OBJECT</td>
    <td>M</td>
    <td>Y</td>
    <td>the part of the input parameter that is responsible for the error (for debugging purposes)</td>
  </tr>
  <tr>
    <td>error_code</td>
    <td></td>
    <td>M</td>
    <td>N</td>
    <td>error code (will be implemented in future version)</td>
  </tr>
</table>
