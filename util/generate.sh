#!/bin/bash

INFILE=$1

read -d '' group_sql << EOF
	select 
		(DISTRKOD % 100000) / 1000 as landskapskod,
		case (DISTRKOD % 100000) / 1000
			when 1 then 'Skåne'
			when 2 then 'Blekinge'
			when 3 then 'Öland'
			when 4 then 'Halland'
			when 5 then 'Småland'
			when 6 then 'Gotland'
			when 7 then 'Västergötland'
			when 8 then 'Östergötland'
			when 9 then 'Bohuslän'
			when 10 then 'Dalsland'
			when 11 then 'Närke'
			when 12 then 'Södermanland'
			when 13 then 'Värmland'
			when 14 then 'Västmanland'
			when 15 then 'Uppland'
			when 16 then 'Gästrikland'
			when 17 then 'Dalarna'
			when 18 then 'Hälsingland'
			when 19 then 'Härjedalen'
			when 20 then 'Medelpad'
			when 21 then 'Ångermanland'
			when 22 then 'Jämtland'
			when 23 then 'Västerbotten'
			when 24 then 'Lappland'
			when 25 then 'Norrbotten'
		end as landskap,
		(DISTRKOD / 100000) as landsdelskod,
		case (DISTRKOD / 100000)
			when 1 then 'Götaland'
			when 2 then 'Svealand'
			when 3 then 'Norrland'
		end as landsdel,
		ST_Union(ST_Buffer(geometry, 1)) as geometry 
	from Distrikt_v1
	group by (DISTRKOD % 100000) / 1000
EOF

temp=`mktemp landskapXXXXXX.sqlite`
rm $temp
ogr2ogr $temp $1 -dialect sqlite -sql "$group_sql" -simplify 5 -f sqlite -t_srs EPSG:4326

vrt=`mktemp landskapXXXXXX.vrt`
cat >$vrt <<EOF
<OGRVRTDataSource>
<OGRVRTLayer name="src_landskap">
    <SrcDataSource>$temp</SrcDataSource>
    <SrcLayer>select</SrcLayer>
</OGRVRTLayer>
<OGRVRTLayer name="border">
    <SrcDataSource>util/swedish_border.sqlite</SrcDataSource>
    <SrcLayer>swedish_border</SrcLayer>
</OGRVRTLayer>
</OGRVRTDataSource>
EOF

read -d '' buffer_sql << EOF
	select ST_Intersection(a.Geometry, b.Geometry) as Geometry, a.landskapskod, a.landskap, a.landsdelskod, a.landsdel \
	FROM src_landskap a, border b
EOF

ogr2ogr svenska-landskap-klippt.geo.json $vrt -dialect sqlite -sql "$buffer_sql" -f GeoJSON -lco COORDINATE_PRECISION=5 -lco RFC7946=YES
ogr2ogr svenska-landskap.geo.json $temp -f GeoJSON -lco COORDINATE_PRECISION=5 -lco RFC7946=YES
rm $temp
rm $vrt
