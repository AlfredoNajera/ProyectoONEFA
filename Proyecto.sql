/* =====================================================================
	Proyecto Final de Bases de datos.

	Equipo: 7
	Integrante 1: Nájera Nájera Alfredo
	Integrante 2: ---------------------
	Integrante 3: ---------------------
	Integrante 4: ---------------------

=======================================================================*/

/* ========================================================
   Seccion 1
   Consultas
=========================================================== */

-- 1. Todos los datos de los entrenadores cuyo apellido es 'Tomlin', 'Harbaugh' o 'Gruden'
select * from entrenador where apellido_entrenador="Harbaugh" or apellido_entrenador="Tomlin" or apellido_entrenador="Gruden";

-- 2. Todos los datos de los estadios y el nombre de la ciudad, de los estadios cuya grama es "Natural" y su capacidad está entre 60,000 y 93,000
select e.id_estadio,e.nombre_estadio,e.capacidad,e.grama,e.condicion,e.anyo_construccion,c.id_ciudad,c.nombre_ciudad from estadio e join ciudad c using(id_ciudad) where grama="Natural" and (capacidad>=60000 and capacidad<=93000);

-- 3. Número total de ciudades agrupadas por clima
select clima,count(id_ciudad) as "total_ciudades" from ciudad group by 1 order by 1;

-- 4. El nombre del equipo y año de fundación, nombre y apellido de los entrenadores de un equipo cuyo nombre comienza con las letras "C", "M" o "W" y su año de fundación (anyo_fund) es menor o igual a 1980
select e.nombre_equipo,e.anyo_fund,eee.nombre_entrenador,eee.apellido_entrenador from equipo e left join equipo_entrenador ee using(id_equipo) left join entrenador eee using(id_entrenador) where (e.nombre_equipo like "C%" or e.nombre_equipo like "M%" or e.nombre_equipo like "W%") and anyo_fund<=1980;

-- 5. Nombre, apellido, fecha de nacimiento, universidad y número de carries del runner que menos carries tiene
select nombre_jugador,apellido_jugador,fecha_nacimiento,universidad,carries from jugador join runner using(id_jugador) where carries=(select min(carries) from runner);

-- 6. El nombre y apellido de los jugadores que: sean receivers con más de 100 recepciones (rec) y pertenzcan a un equipo fundado después de 1960 o que sean runners con al menos 220 acarreos (carries) y con exactamente 3 fumbles, ordenado por nombre del jugador
select j.nombre_jugador,j.apellido_jugador from jugador j join receiver r  using(id_jugador) join jugador_equipo as je on je.id_jugador=j.id_jugador join equipo e using(id_equipo)
where r.rec > 100 and anyo_fund > 1960 union select j.nombre_jugador,j.apellido_jugador from jugador j  join runner run on run.id_jugador = j.id_jugador join jugador_equipo as je on je.id_jugador=j.id_jugador
join equipo e using(id_equipo) where run.carries >= 220 and run.fumbles = 3 order by 1;

-- 7. El id y nombre del equipo, nombre de la ciudad, ingreso promedio y record de juegos perdidos de los equipos que tienen el máximo record de juegos perdidos y que pertenecen a alguna ciudad con ingreso promedio mayor 47
select e.id_equipo,e.nombre_equipo,c.nombre_ciudad,c.ingreso_promedio,e.record_p from equipo e left join equipo_ciudad ec using(id_equipo) left join ciudad c using(id_ciudad) where e.record_p=(select max(e.record_p) from equipo e left join 
equipo_ciudad ec using(id_equipo) left join ciudad c using(id_ciudad) where ingreso_promedio>47) and ingreso_promedio>47;

-- 8. El nombre y apellido de los Runners que han jugado en dos equipos diferentes y cuyo año de adquisición sea a partir de 1990 ordenado por nombre del jugador
select nombre_jugador,apellido_jugador from (select id_jugador,nombre_jugador,apellido_jugador,nombre_equipo,anyo_adquirido,count(id_jugador) i from runner 
left join jugador using(id_jugador) left join jugador_equipo using(id_jugador) left join equipo using(id_equipo) group by 1 having i=2 and anyo_adquirido>=1990
 order by 2) as M;

-- 9. De las 5 ciudades con mayor número de habitantes ¿Cuál es la que tiene la menor cantidad de equipos?
select nombre_ciudad from (select nombre_ciudad,min(i) from (select id_ciudad,nombre_ciudad,habitantes,count(id_equipo) 
i from ciudad left join equipo_ciudad using(id_ciudad) group by 1 order by 3 desc limit 5) as M where i>0) as MM;

-- 10. Número total de receptores agrupados por la ciudad donde juega su equipo y ordenados por el nombre de la ciudad de manera ascendente. Los equipos considerados deben tener record de más de tres perdidos (record_p) y ser de la conferencia 'Nacional'
select nombre_ciudad,count(je.id_jugador) as total_receptores from ciudad c join equipo_ciudad ec on ec.id_ciudad = c.id_ciudad join equipo as e on e.id_equipo = ec.id_equipo join jugador_equipo je on je.id_equipo = e.id_equipo 
join jugador j on j.id_jugador = je.id_jugador join receiver r on r.id_jugador = j.id_jugador where record_p > 3 and conferencia = 'Nacional' group by 1 order by 1;


/* ========================================================
   Seccion 2.
   Procedimientos Almacenados
=========================================================== */

-- 1. Todos los datos de los equipos cuyo nombre comienza con las letras que indique el usuario. Ejemplo: call equipos('T','D','P');
drop procedure if exists equipos;
delimiter //
create procedure equipos(IN l1 char(1),IN l2 char(1),IN l3 char(3))
begin
select * from equipo where nombre_equipo like concat(l1,'%') or nombre_equipo like concat(l2,'%') or nombre_equipo like concat(l3,'%');
end;
//
delimiter ;

-- 2. Identificador y nombre de los equipos que tienen más de 5 runners registrados, ordenados de manera descendente por el nombre del equipo. Ejemplo: call equipoRunners();
drop procedure if exists equipoRunners;
delimiter //
create procedure equipoRunners()
begin
select id_equipo,nombre_equipo from runner join jugador using(id_jugador) join jugador_equipo using(id_jugador) 
join equipo using(id_equipo) group by 1 having count(id_jugador)>5 order by 2 desc;
end;
//
delimiter ;

-- 3. El nombre y apellido del entrenador y nombre del equipo que ha ganado o perdido más partidos de local o visitante, según lo indique el usuario. Ejemplo: call maximo(‘ganador’,’local’);
drop procedure if exists maximo;
delimiter //
create procedure maximo(IN l1 varchar(10),IN l2 varchar(10))
begin

if l1="perdedor" and l2="local" then
select nombre_entrenador,apellido_entrenador,nombre_equipo from (select nombre_entrenador,apellido_entrenador,nombre_equipo,count(resultado) as r from(select nombre_entrenador,apellido_entrenador,nombre_equipo,resultado 
from (select nombre_entrenador,apellido_entrenador,nombre_equipo,(marcador_l-marcador_v) as resultado from entrenador join equipo_entrenador using(id_entrenador) 
join equipo using(id_equipo) join partido on id_equipo=id_equipo_l) as M where resultado<0) as MM group by 1,2,3) as W where r=(select max(r) from (select nombre_entrenador,apellido_entrenador,nombre_equipo,count(resultado) as r from(select nombre_entrenador,apellido_entrenador,nombre_equipo,resultado 
from (select nombre_entrenador,apellido_entrenador,nombre_equipo,(marcador_l-marcador_v) as resultado from entrenador join equipo_entrenador using(id_entrenador) 
join equipo using(id_equipo) join partido on id_equipo=id_equipo_l) as M where resultado<0) as MM group by 1,2,3) as MMM);

elseif l1="ganador" and l2="local" then
select nombre_entrenador,apellido_entrenador,nombre_equipo from (select nombre_entrenador,apellido_entrenador,nombre_equipo,count(resultado) as r from(select nombre_entrenador,apellido_entrenador,nombre_equipo,resultado 
from (select nombre_entrenador,apellido_entrenador,nombre_equipo,(marcador_l-marcador_v) as resultado from entrenador join equipo_entrenador using(id_entrenador) 
join equipo using(id_equipo) join partido on id_equipo=id_equipo_l) as M where resultado>0) as MM group by 1,2,3) as W where r=(select max(r) from (select nombre_entrenador,apellido_entrenador,nombre_equipo,count(resultado) as r from(select nombre_entrenador,apellido_entrenador,nombre_equipo,resultado 
from (select nombre_entrenador,apellido_entrenador,nombre_equipo,(marcador_l-marcador_v) as resultado from entrenador join equipo_entrenador using(id_entrenador) 
join equipo using(id_equipo) join partido on id_equipo=id_equipo_l) as M where resultado>0) as MM group by 1,2,3) as MMM);

elseif l1="perdedor" and l2="visitante" then
select nombre_entrenador,apellido_entrenador,nombre_equipo from (select nombre_entrenador,apellido_entrenador,nombre_equipo,count(resultado) as r from(select nombre_entrenador,apellido_entrenador,nombre_equipo,resultado 
from (select nombre_entrenador,apellido_entrenador,nombre_equipo,(marcador_l-marcador_v) as resultado from entrenador join equipo_entrenador using(id_entrenador) 
join equipo using(id_equipo) join partido on id_equipo=id_equipo_v) as M where resultado>0) as MM group by 1,2,3) as W where r=(select max(r) from (select nombre_entrenador,apellido_entrenador,nombre_equipo,count(resultado) as r from(select nombre_entrenador,apellido_entrenador,nombre_equipo,resultado 
from (select nombre_entrenador,apellido_entrenador,nombre_equipo,(marcador_l-marcador_v) as resultado from entrenador join equipo_entrenador using(id_entrenador) 
join equipo using(id_equipo) join partido on id_equipo=id_equipo_v) as M where resultado>0) as MM group by 1,2,3) as MMM);

elseif l1="ganador" and l2="visitante" then
select nombre_entrenador,apellido_entrenador,nombre_equipo from (select nombre_entrenador,apellido_entrenador,nombre_equipo,count(resultado) as r from(select nombre_entrenador,apellido_entrenador,nombre_equipo,resultado 
from (select nombre_entrenador,apellido_entrenador,nombre_equipo,(marcador_l-marcador_v) as resultado from entrenador join equipo_entrenador using(id_entrenador) 
join equipo using(id_equipo) join partido on id_equipo=id_equipo_v) as M where resultado<0) as MM group by 1,2,3) as W where r=(select max(r) from (select nombre_entrenador,apellido_entrenador,nombre_equipo,count(resultado) as r from(select nombre_entrenador,apellido_entrenador,nombre_equipo,resultado 
from (select nombre_entrenador,apellido_entrenador,nombre_equipo,(marcador_l-marcador_v) as resultado from entrenador join equipo_entrenador using(id_entrenador) 
join equipo using(id_equipo) join partido on id_equipo=id_equipo_v) as M where resultado<0) as MM group by 1,2,3) as MMM);

else
select "escribe algo correcto" as Sugerencia;

end if;
end;
//
delimiter ;

-- 4. La posición y el total de pancakes que suman los jugadores de línea ofensiva que nacieron después del año dado por el usuario, agrupados por posición y ordenados de manera descendente. Ejemplo: call totalPancakes(1980);
drop procedure if exists totalPancakes;
delimiter //
create procedure totalPancakes(IN x int)
begin
select posicion,sum(pancakes) as pancakes from (select posicion,pancakes,fecha_nacimiento from linea_ofensiva join jugador using(id_jugador) where year(fecha_nacimiento)>x) as M group by 1;
end;
//
delimiter ;

-- 5. El identificador, nombre y número de partidos en los que ganó un equipo visitante que tenía record de juegos ganados igual a la cantidad que indique el usuario. Ejemplo: call ganoVisitante(9);
drop procedure if exists ganoVisitante;
delimiter //
create procedure ganoVisitante(IN x int)
begin
select id_equipo_v, nombre_equipo, count(p) as "partidos_ganados" from (select id_equipo_v,nombre_equipo,p,record_g from 
(select id_equipo_v,nombre_equipo,(marcador_v-marcador_l) as p,record_g from partido join equipo on id_equipo=id_equipo_v) as M where p>0 and record_g=x) 
as MM group by 1,2;
end;
//
delimiter ;

/* ========================================================
       Ejecutar los procedimientos
=========================================================== */

-- Ejecutar el procedimiento 1:
call equipos('T','D','P'); 
call equipos('A','M','R'); 

-- Ejecutar el procedimiento 2:
call equipoRunners();

-- Ejecutar el procedimiento 3:
call maximo('ganador','local');
call maximo('perdedor','visitante'); 
call maximo('perdedor','local');
call maximo('ganador','visitante');

-- Ejecutar el procedimiento 4:
call totalPancakes(1980);
call totalPancakes(1970);
call totalPancakes(1978);

-- Ejecutar el procedimiento 5:
call ganoVisitante(9);
call ganoVisitante(4);
call ganoVisitante(16);
call ganoVisitante(13);



/* ===== Fin del proyecto ========== */