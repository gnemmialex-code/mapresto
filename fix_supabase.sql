-- Correction encodage (accents casses) + suppression lignes test.
-- A executer dans Supabase > SQL Editor.

UPDATE places SET ambiance_tags = ARRAY['mystérieux','historique']::text[] WHERE id = 'd9b87969-143a-441f-b9f7-081b3a8bde91'; -- Bunker de la Gare de l'Est
UPDATE places SET ambiance_tags = ARRAY['paisible','bucolique','caché']::text[], address = 'Cité du Figuier, 75011 Paris' WHERE id = '0fb257b6-dad3-42ee-9ce3-a5fdce63b417'; -- Cité du Figuier
UPDATE places SET address = 'Cité Florale, 75013 Paris' WHERE id = 'a15000ca-6ee3-4b4a-b76c-e5185f057d84'; -- Cité Florale
UPDATE places SET ambiance_tags = ARRAY['insolite','feutré','curieux']::text[] WHERE id = '2d191576-3161-4c6c-a2a5-d40e09a603a6'; -- Deyrolle
UPDATE places SET ambiance_tags = ARRAY['historique','élégant','calme']::text[] WHERE id = '53fa8672-16d5-46fd-a447-37b9d1020638'; -- Galerie Véro-Dodat
UPDATE places SET ambiance_tags = ARRAY['insolite','dépaysant','historique']::text[] WHERE id = '10d4446b-8c55-4b45-9809-64183dfba808'; -- Maison Loo (Pagode)
UPDATE places SET ambiance_tags = ARRAY['dépaysant','paisible','contemplatif']::text[] WHERE id = 'f8ad7490-db3e-4854-82a9-c0aea28a97ec'; -- Musée Albert-Kahn
UPDATE places SET ambiance_tags = ARRAY['mystérieux','ludique']::text[] WHERE id = 'fe529d6f-f219-48be-8489-cedc6565f381'; -- Passage secret rue des Anglais
UPDATE places SET ambiance_tags = ARRAY['insolite','décontracté']::text[] WHERE id = 'e2fc9386-284d-4fe8-ba49-189f78450a14'; -- Piscine Roger Le Gall (créneaux naturistes)
UPDATE places SET address = 'Quartier de la Mouzaéa, 75019 Paris' WHERE id = 'cf75678f-9d35-4e24-8d71-a1ecc4755e7d'; -- Quartier de la Mouzaéa
UPDATE places SET ambiance_tags = ARRAY['spirituel','dépaysant','paisible']::text[] WHERE id = 'c41b48ab-a1f1-401a-a842-7c81df0e9c2b'; -- Temple Ganesh
UPDATE places SET ambiance_tags = ARRAY['chic','feutré','élégant']::text[] WHERE id = '2275a060-ac09-453b-b071-376fbcf71721'; -- Bar 228
UPDATE places SET ambiance_tags = ARRAY['chic','feutré','intimiste']::text[] WHERE id = '5b0fece3-5c56-49cc-8b09-945a87cb75ca'; -- Doris Bar
UPDATE places SET ambiance_tags = ARRAY['festif','intimiste','décontracté']::text[], address = '30 Rue René Boulanger, 75010 Paris' WHERE id = 'eff94ad6-46c2-4906-9c57-f2e3afe10d6a'; -- Lavomatic
UPDATE places SET ambiance_tags = ARRAY['romantique','sensuel','feutré']::text[] WHERE id = '17446c08-7e99-4044-9539-6f1351409962'; -- Maison Souquet
UPDATE places SET ambiance_tags = ARRAY['intimiste','vintage','feutré']::text[] WHERE id = 'd0e7b89d-8ad7-45f7-a7be-b5ca8af1faa0'; -- Moonshiner
UPDATE places SET ambiance_tags = ARRAY['festif','décontracté','convivial']::text[] WHERE id = '5529da4b-2a69-4a38-8155-ae56f5ace729'; -- Rosa Bonheur sur Seine
UPDATE places SET ambiance_tags = ARRAY['festif','branché','chic']::text[], address = '10 Rue Agrippa d''Aubigné, 75004 Paris' WHERE id = '7100735f-35dc-41a0-9060-858edfa1cf49'; -- Bonnie
UPDATE places SET ambiance_tags = ARRAY['feutré','historique','romantique']::text[] WHERE id = 'f13b4af3-0619-48ab-871a-b4670d557482'; -- Café Laurent
UPDATE places SET ambiance_tags = ARRAY['festif','convivial','branché']::text[] WHERE id = '41cd0ee8-9668-4a85-a036-34b80cd2d750'; -- Candelaria
UPDATE places SET ambiance_tags = ARRAY['intimiste','bohème','convivial']::text[], music_tags = ARRAY['lounge','éclectique']::text[] WHERE id = '576a28e3-b3bb-4cbf-a517-2e9d3a20bea4'; -- Derrière
UPDATE places SET ambiance_tags = ARRAY['chic','festif','branché']::text[], address = '1 Place du Trocadéro, 75016 Paris' WHERE id = 'fc3b377c-ab08-4ed8-8959-4dab6efee47b'; -- Girafe
UPDATE places SET ambiance_tags = ARRAY['paisible','dépaysant','élégant']::text[], address = '6 Place d''Iéna, 75116 Paris ' WHERE id = 'c2cfbcd8-dbf8-49e8-87a9-b47bf3ab95a6'; -- Hanok
UPDATE places SET ambiance_tags = ARRAY['chic','élégant','gastronomique']::text[] WHERE id = 'e16f9f92-5c08-463e-b6bc-e25717543c63'; -- La Halle aux Grains
UPDATE places SET address = '2e étage Tour Eiffel, Av. Gustave Eiffel, 75007 Paris' WHERE id = '9c12b464-d2d4-42ba-90c6-1cb49b2c4c71'; -- Le Jules Verne
UPDATE places SET ambiance_tags = ARRAY['chic','historique','élégant']::text[] WHERE id = '84fc1636-d0d6-4e48-8490-9a747ff6ef3f'; -- Le Train Bleu
UPDATE places SET ambiance_tags = ARRAY['romantique','élégant','gastronomique']::text[] WHERE id = 'b00ad27e-b321-4efa-b842-46d0f8c3849a'; -- Les Ombres
UPDATE places SET ambiance_tags = ARRAY['chic','élégant','branché']::text[] WHERE id = '6c4abe63-f36e-44a1-a9a8-ff0802186700'; -- Monsieur Bleu
UPDATE places SET ambiance_tags = ARRAY['festif','branché','convivial']::text[] WHERE id = '3e9e8ac5-b2c4-418c-b63b-e6d1c0e6e7f3'; -- Pink Mamma

-- Lignes test marquees "A SUPPRIMER" :
DELETE FROM places WHERE id IN ('47c53240-8a74-4b88-b8dc-6615e7fd628c', '8a85307b-6285-4377-8234-f4b770a03349', 'ffa12c41-c7ef-4730-a5ba-913644b39d87', '0fb457af-80f0-4a2a-b405-08d249932b04', '84ba5282-308a-4249-8b40-7a267cef291c', '317751ce-e123-4898-8e97-9a1dfabb7377');
