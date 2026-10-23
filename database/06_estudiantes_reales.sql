-- =============================================================================
-- SISTEMA WEB DE MATRÍCULA UNIVERSITARIA - UNJBG
-- INSERCIÓN DE ESTUDIANTES REALES (67 alumnos)
-- Password para todos: '123456'
-- Hash Bcrypt: '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2'
-- NOTA: Ninguno es INGRESANTE (ingresantes = año 2026+)
--       2024 → Regular (1er/2do ciclo, promedio 0-14)
--       2022 → Destacado/Regular (5to-6to ciclo)
--       2021 → Destacado/Regular/Especial (7mo-8vo ciclo)
--       2020 → Regular/Especial (9no-10mo ciclo)
-- condicion_academica: REGULAR (promedio 11-14.99, 23 créditos)
--                      DESTACADO (promedio >=15, 28 créditos)
--                      ESPECIAL  (promedio <11, 11 créditos)
-- =============================================================================

USE sistema_matricula;

INSERT INTO estudiante
  (codigo, dni, nombres, apellidos, correo_institucional, password_hash,
   id_escuela, id_sede, es_ingresante, condicion_academica,
   promedio_ponderado, creditos_permitidos, estado)
VALUES
-- ═══════════════ PROMOCIÓN 2024 (Ciclo 1-2, REGULAR) ═══════════════
('2024-119001','72001001','David','Avalos Mamani',             'davalosmam@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.30,23,'ACTIVO'),
('2024-119002','72001002','Piero Gabriel','García Mendoza',    'pgarciamen@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.75,23,'ACTIVO'),
('2024-119003','72001003','Cristhian Miguel','Mamani Quispe',  'cmamaniqu@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.90,23,'ACTIVO'),
('2024-119004','72001004','Jair Mark','Mendoza Flores',        'jmendozafl@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',14.10,23,'ACTIVO'),
('2024-119005','72001005','Fabricio Renato','Monroy Fuentes',  'fmonroyfu@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.20,23,'ACTIVO'),
('2024-119006','72001006','William Andre','Nina Estuco',       'wninaes@unjbg.edu.pe',     '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.60,23,'ACTIVO'),
('2024-119007','72001007','Pedro Pablo','Ninaja Medina',       'pninajame@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.45,23,'ACTIVO'),
('2024-119008','72001008','Gabriel Stefano','Peñaloza Gutierrez','gpenalozag@unjbg.edu.pe','$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.80,23,'ACTIVO'),
('2024-119009','72001009','Raul Farid Banchello','Pino Rojas', 'rpinoroj@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.05,23,'ACTIVO'),
('2024-119010','72001010','Carlos Daniel','Torres Valdez',     'ctorresval@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',14.50,23,'ACTIVO'),
('2024-119011','72001011','Aron Rene','Cachicatari Quito',     'acachicatq@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.70,23,'ACTIVO'),
('2024-119012','72001012','Alex Jeanpier','Chata Chino',       'achatachi@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.60,23,'ACTIVO'),
('2024-119013','72001013','Danny Yair','Luque Pari',           'dluquepari@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.40,23,'ACTIVO'),
('2024-119014','72001014','Angel Anibal','Mamani Casilla',     'amamanicas@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.90,23,'ACTIVO'),
('2024-119015','72001015','Diana Belinda','Mamani Ramos',      'dmamaniram@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',14.00,23,'ACTIVO'),
('2024-119016','72001016','Diego Jeancarlos','Ramos Marca',    'dramosmarc@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.20,23,'ACTIVO'),
('2024-119017','72001017','Jose Antonio','Vilcanqui Chambi',   'jvilcanqch@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.55,23,'ACTIVO'),
('2024-119018','72001018','Patricia Mireya','Aduvire Huanca',  'paduvirehu@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',14.20,23,'ACTIVO'),
('2024-119019','72001019','Ronald','Choquehuanca Rafael',      'rchoquera@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.10,23,'ACTIVO'),
('2024-119020','72001020','Alexander Bernabe','Flores Cutipa', 'aflorescut@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.00,23,'ACTIVO'),
('2024-119021','72001021','Johan Anibal','Mamani Catacora',    'jmamanicat@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.70,23,'ACTIVO'),
('2024-119022','72001022','Yhulian Nayeli','Maquera Flores',   'ymaqueflo@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',14.30,23,'ACTIVO'),
('2024-119023','72001023','Pedro Czar Paolo','Serrano Yanapa', 'pserranoyan@unjbg.edu.pe', '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.80,23,'ACTIVO'),
('2024-119024','72001024','Adrian Eliel','Socualaya Feliciano','asociuala@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.65,23,'ACTIVO'),
('2024-119025','72001025','Luciano Fabricio','Velez Miranda',  'lvelezmira@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.30,23,'ACTIVO'),
('2024-119026','72001026','Jhonel Gerson','Apaza Pacompia',    'japazapac@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.45,23,'ACTIVO'),
('2024-119027','72001027','Jhosep Rodrigo','Arocutipa Mamani', 'jarocutima@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.90,23,'ACTIVO'),
('2024-119028','72001028','Dennis Fidel','Aruhuanca Huanca',   'daruhuanhu@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.15,23,'ACTIVO'),
('2024-119029','72001029','Fernando Jesus','Briceño Pihuaycho','fbricenopi@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.30,23,'ACTIVO'),
('2024-119030','72001030','Luis Fernando','Chura Coaquira',    'lchuraco@unjbg.edu.pe',    '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.85,23,'ACTIVO'),
('2024-119031','72001031','Luis Fernando','Condori Caljaro',   'lcondoricalj@unjbg.edu.pe','$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',14.40,23,'ACTIVO'),
('2024-119032','72001032','Stip Leonel Yordy','Corimaya Chura','scorimayach@unjbg.edu.pe', '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.55,23,'ACTIVO'),
('2024-119033','72001033','Ronald Alexander','Huaman Huanca',  'rhuamanhu@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.15,23,'ACTIVO'),
('2024-119034','72001034','Arturo Willy','Montalico Llica',    'montallica@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.50,23,'ACTIVO'),
('2024-119035','72001035','Giorgini Disalvatore','Pacci Perez','gpacciperez@unjbg.edu.pe', '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',14.60,23,'ACTIVO'),
('2024-119036','72001036','Alejandra Del Rosario','Ramos Mamani','aramosma@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.10,23,'ACTIVO'),
('2024-119038','72001038','Alexander Jesus','Tellez Mesa',     'atellezme@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.35,23,'ACTIVO'),
('2024-119039','72001039','Dante Vicente','Alvarez Tapia',     'dalvarezta@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.95,23,'ACTIVO'),
('2024-119040','72001040','River','Calizaya Pariguana',        'rcalizayap@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.40,23,'ACTIVO'),
('2024-119041','72001041','Cesar Jimmy','Chambe Mamani',       'cchambema@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.75,23,'ACTIVO'),
('2024-119042','72001042','Alexander Fermin Dario','Chicalla Garcia','achicallaga@unjbg.edu.pe','$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',14.05,23,'ACTIVO'),
('2024-119043','72001043','Brayan','Chino Valeriano',          'bchinoval@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.95,23,'ACTIVO'),
('2024-119044','72001044','Alexandra Valeria','Choque Onofre', 'achoqueon@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.50,23,'ACTIVO'),
('2024-119046','72001046','Wesley Rivaldo','Laura Choquejahua','wlaurachoq@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.20,23,'ACTIVO'),
('2024-119047','72001047','Ivan','Maquera Cabrera',            'imaquecab@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',14.70,23,'ACTIVO'),
('2024-119048','72001048','Dany Ronaldo','Muriel Herencia',    'dmurielhe@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.65,23,'ACTIVO'),
('2024-119049','72001049','Hugo Antonio','Ordono Quispe',      'hordono@unjbg.edu.pe',     '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.85,23,'ACTIVO'),
('2024-119050','72001050','Brayhan Deyvid','Quispe Cama',      'bquispeca@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.50,23,'ACTIVO'),
('2024-119051','72001051','Anette Matiel','Quispe Huillca',    'aquispehu@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.25,23,'ACTIVO'),
('2024-119052','72001052','Willian Arturo','Salazar Quispe',   'wsalazarq@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.10,23,'ACTIVO'),
('2024-119053','72001053','Renzo Julian','Vicente Ticona',     'rvicenteti@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',14.15,23,'ACTIVO'),
('2024-119054','72001054','Jairo Brayan','Zegarra Gutierrez',  'jzegarrag@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.65,23,'ACTIVO'),
('2024-119055','72001055','Franklin Cristofier','Anahua Cahuachia','fanauacha@unjbg.edu.pe','$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.70,23,'ACTIVO'),
('2024-119056','72001056','Elvis Ronald','Arocutipa Quispe',   'earocutiq@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.25,23,'ACTIVO'),
('2024-119057','72001057','Angel David','Catari Paccoricuna',  'acataripac@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.85,23,'ACTIVO'),
('2024-119059','72001059','Matias Fabricio','Copaja Segura',   'mcopajase@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',14.45,23,'ACTIVO'),
('2024-119060','72001060','Luis David','Cruz Llica',           'lcruzlli@unjbg.edu.pe',    '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.75,23,'ACTIVO'),
('2024-119061','72001061','Cristian Rene','Fernandez Condori', 'cfernandco@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.45,23,'ACTIVO'),
('2024-119062','72001062','Alison Khiara','Flores Hallasi',    'afloreshal@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'DESTACADO',15.10,28,'ACTIVO'),
('2024-119063','72001063','Frank Edson','Mamani Cruz',         'fmamamicru@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',12.00,23,'ACTIVO'),
('2024-119064','72001064','Oscar Alejandro','Ticona Fernandez','oticona@unjbg.edu.pe',     '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',13.60,23,'ACTIVO'),
('2024-119065','72001065','Sebastian Andre','Valdez Condori',  'svaldezco@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',11.55,23,'ACTIVO'),
('2024-119066','72001066','Jhon Andrioly','Zenteno Sosa',      'jzentenos@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR',14.80,23,'ACTIVO'),

-- ═══════════════ PROMOCIÓN 2022 (Ciclo 5-6, DESTACADO) ═══════════════
('2022-119047','72002047','Anthony Zenon','Jimenez Cani',      'ajimenezca@unjbg.edu.pe',  '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'DESTACADO',16.20,28,'ACTIVO'),

-- ═══════════════ PROMOCIÓN 2021 (Ciclo 7-8) ═══════════════
('2021-121027','72003027','Pierrette Ahmed Raksel','Chavez Alvarado','pchavezalv@unjbg.edu.pe','$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'DESTACADO',17.40,28,'ACTIVO'),
('2021-119119','72003119','Helber Junior','Lope Apomayta',     'hlopeapo@unjbg.edu.pe',    '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR', 13.90,23,'ACTIVO'),
('2021-119030','72003030','Maryori Areli','Tito Aparicio',     'mtitoapar@unjbg.edu.pe',   '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'ESPECIAL', 9.80,11,'ACTIVO'),

-- ═══════════════ PROMOCIÓN 2020 (Ciclo 9-10, REGULAR) ═══════════════
('2020-119006','72004006','Jose Luis','Pino Condori',          'jpinocon@unjbg.edu.pe',    '$2y$10$wS9lG6H6Bupx41XpI0G7p.xI9bN52Fh3gV6NlWfVwVv5yI3z6S6Q2',1,1,FALSE,'REGULAR', 12.70,23,'ACTIVO');

-- ═══════════════════════════════════════════════════════════════
-- RESUMEN:
--  Total: 67 estudiantes
--  REGULAR:   63 alumnos (23 créditos)
--  DESTACADO:  3 alumnos (28 créditos) — Flores Hallasi, Jimenez Cañi, Chavez Alvarado, Pierrette
--  ESPECIAL:   1 alumno  (11 créditos) — Tito Aparicio
--  Contraseña: 123456 (hash bcrypt estándar)
--  DNI:        serie 7200xxxx, 7200xxxx (inventados)
--  es_ingresante: FALSE para todos (ingresantes = código año 2026)
-- ═══════════════════════════════════════════════════════════════
