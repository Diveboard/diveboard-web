# encoding: UTF-8

class CreateGeonamesCountries < ActiveRecord::Migration
  def self.up
    #ISO	ISO3	ISO-Numeric	fips	Country	Capital	Area(in sq km)	Population	Continent	tld	CurrencyCode	CurrencyName	Phone	Postal Code Format	Postal Code Regex	Languages	geonameid	neighbours	EquivalentFipsCode
    # NEED TO ADD
    # currency_symbol 
    #depencensies : ISO, depends_from 
    
    
    # encoding: UTF-8
    Encoding.default_external = 'utf-8' 
    Encoding.default_internal = 'utf-8'
    
    dependencies = "AN,NL,PCLIX
AQ,GB/NZ/FR/NO/AU/CL/AR,ADM1
AS,US,ADMD
AW,NL,PCLIX
AX,FI,ISLS
BL,FR,PCLIX
BV,NO,PCLD
CK,NZ,PCLS
CX,AU,PCLD
FK,GB,PCLD
FM,US,PCLF
FO,DK,ADM1
GF,FR,PCLD
GG,GB,PCLD
GI,GB,PCLD
GL,DK,PCLD
GP,FR,PCLD
GU,US,ISL
HK,CN,PCLS
HM,AU,PCLD
IM,GB,PCLD
IO,GB,PCLD
JE,GB,PCLD
MF,FR/NL,PCLIX
MH,US,PCLF
MO,CN,PCLS
MP,US,ADMD
MQ,FR,PCLD
MS,GB,PCLD
NU,NZ,PCLS
PF,FR,PCLD
PM,FR,PCLD
PN,GB,PCLD
PR,US,PCLD
RE,FR,PCLD
SH,GB,PCLD
SJ,NO,TERR
TC,GB,PCLD
TF,FR,PCLIX
TK,NZ,PCLD
UM,US,ADMD
VG,GB,PCLD
VI,US,ADMD
WF,FR,PCLD
YT,FR,PCLD"

  currency_symbols = 'AED,د.إ
AFN,؋
ALL,L
AMD,դր.
ANG,ƒ
AOA,Kz
ARS,$
AUD,$
AWG,ƒ
AZN,m
BAM,KM
BBD,$
BDT,৳
BGN,лв
BHD,ب.د
BIF,Fr
BMD,$
BND,$
BOB,Bs.
BRL,R$
BSD,$
BTN,Nu
BWP,P
BYR,Br
BZD,$
CAD,$
CDF,Fr
CHF,Fr
CLP,$
CNY,¥
COP,$
CRC,₡
CUP,$
CVE,$
CZK,Kč
DJF,Fr
DKK,kr
DOP,$
DZD,د.ج
EEK,KR
EGP,£,ج.م
ERN,Nfk
ETB,Br
EUR,€
FJD,$
FKP,£
GBP,£
GEL,ლ
GHS,₵
GIP,£
GMD,D
GNF,Fr
GTQ,Q
GYD,$
HKD,$
HNL,L
HRK,kn
HTG,G
HUF,Ft
IDR,Rp
ILS,₪
INR,₨
IQD,ع.د
IRR,﷼
ISK,kr
JMD,$
JOD,د.ا
JPY,¥
KES,Sh
KGS,лв
KHR,៛
KMF,Fr
KPW,₩
KRW,₩
KWD,د.ك
KYD,$
KZT,Т
LAK,₭
LBP,ل.ل
LKR,ரூ
LRD,$
LSL,L
LTL,Lt
LVL,Ls
LYD,ل.د
MAD,د.م.
MDL,L
MGA,Ar
MKD,ден
MMK,K
MNT,₮
MOP,P
MRO,UM
MUR,₨
MVR,ރ.
MWK,MK
MXN,$
MYR,RM
MZN,MT
NAD,$
NGN,₦
NIO,C$
NOK,kr
NPR,₨
NZD,$
OMR,ر.ع.
PAB,B/.
PEN,S/.
PGK,K
PHP,₱
PKR,₨
PLN,zł
PYG,₲
QAR,ر.ق
RON,RON
RSD,RSD
RUB,р.
RWF,Fr
SAR,ر.س
SBD,$
SCR,₨
SDG,S$
SEK,kr
SGD,$
SHP,£
SLL,Le
SOS,Sh
SRD,$
STD,Db
SYP,£,ل.س
SZL,L
THB,฿
TJS,ЅМ
TMT,m
TND,د.ت
TOP,T$
TRY,₤
TTD,$
TWD,$
TZS,Sh
UAH,₴
UGX,Sh
USD,$
UYU,$
UZS,лв
VEF,Bs
VND,₫
VUV,Vt
WST,T
XAF,Fr
XCD,$
XOF,Fr
XPF,Fr
YER,﷼
ZAR,R
ZMK,ZK
ZWL,$'
    
    
    
    create_table :geonames_countries do |t|
      t.string :ISO, :limit => 2
      t.string :ISO3, :limit => 3
      t.string :ISONumeric, :limit =>3
      t.string :name
      t.string :capital
      t.integer :area
      t.integer :population
      t.string :continent, :limit => 2
      t.string :tld, :limit => 4
      t.string :currency_code, :limit => 3
      t.string :currency_name, :limit => 30
      t.string :currency_symbol, :limit => 6
      t.string :phone, :limit => 10
      t.string :postcode, :limit => 10
      t.string :postcode_regexp
      t.string :languages
      t.integer :geonames_id
      t.string :neighbours
      t.string :depends_from
      t.string :feature_code, :limit => 10
    end
    if !File.exists?("/tmp/countryInfo.txt")
      system("cd /tmp && wget http://download.geonames.org/export/dump/countryInfo.txt")
    end
    
    
    config = Rails::Application.instance.config
    database = config.database_configuration[RAILS_ENV]["database"]
    username = config.database_configuration[RAILS_ENV]["username"]
    password = config.database_configuration[RAILS_ENV]["password"]
    command = "mysql -u#{username} -p#{password} #{database} -e \"LOAD DATA LOCAL INFILE '/tmp/countryInfo.txt' INTO TABLE geonames_countries FIELDS TERMINATED BY '\\t' IGNORE 51 LINES (ISO, ISO3, ISONumeric, @dummy , name, capital, area, population, continent, tld, currency_code, currency_name, phone, postcode, postcode_regexp, languages, geonames_id, neighbours);\""
    puts command
    system(command)
    
    add_index :geonames_countries, :ISO
    add_index :geonames_countries, :ISO3
    add_index :geonames_countries, :continent
    add_index :geonames_countries, :geonames_id
    
    dependencies.lines.each do |line|
      execute("UPDATE geonames_countries SET depends_from=\"#{line.split(",")[1]}\" where ISO=\"#{line.split(",")[0]}\"")
    end
    currency_symbols.lines.each do |line|
      execute("UPDATE geonames_countries SET currency_symbol=\"#{line.split(",")[1]}\" where currency_code=\"#{line.split(",")[0]}\" ")
    end  
  end

  def self.down
    drop_table :geonames_countries
  end
  
end
