/// Outil de migration : insère tous les lieux dans Supabase.
///
/// Usage :
///   dart run tools/seed_supabase.dart \
///     --url=https://XXXX.supabase.co \
///     --key=YOUR_SERVICE_ROLE_KEY
///
/// La SERVICE ROLE KEY (pas l'anon key) se trouve dans
///   Supabase Dashboard → Settings → API → service_role
///
/// L'outil utilise uniquement dart:io + dart:convert (aucune dépendance).
library;
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  // -- Lecture des arguments --
  String? url, key;
  for (final a in args) {
    if (a.startsWith('--url=')) url = a.substring(6);
    if (a.startsWith('--key=')) key = a.substring(6);
  }
  if (url == null || key == null) {
    print('Usage: dart run tools/seed_supabase.dart --url=<URL> --key=<SERVICE_ROLE_KEY>');
    exit(1);
  }

  final places = _buildPlaces();
  print('🚀 Envoi de ${places.length} lieux vers Supabase...');

  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('$url/rest/v1/places'),
    );
    request.headers
      ..set('apikey', key)
      ..set('Authorization', 'Bearer $key')
      ..set('Content-Type', 'application/json')
      ..set('Prefer', 'resolution=merge-duplicates');
    request.write(jsonEncode(places));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✓ ${places.length} lieux insérés/mis à jour avec succès!');
    } else {
      print('✗ Erreur HTTP ${response.statusCode}:\n$body');
    }
  } finally {
    client.close();
  }
}

// ---------------------------------------------------------------------------
// Données : tous les lieux de l'app (doit rester synchronisé avec
// mock_data_service.dart). On stocke uniquement les champs "bruts" ;
// les champs dérivés (averagePrice, crowdTags, etc.) sont calculés côté app.
// ---------------------------------------------------------------------------
List<Map<String, dynamic>> _buildPlaces() => [
  // ===================== BARS =====================
  _p('d956884b-be56-404b-ad20-efcaeec10e94','38Riv Jazz Club','bar',48.856472,2.356533,'38 Rue de Rivoli, 75004 Paris',4.7,972,2,['intime','authentique','feutre'],['jazz','live'],['jazz club','cave voutee','jam']),
  _p('2275a060-ac09-453b-b071-376fbcf71721','Bar 228','bar',48.8653326,2.3281374,'228 Rue de Rivoli, 75001 Paris',4.3,246,1,['chic','feutré','élégant'],['jazz','piano'],[]),
  _p('c492ae99-fbbd-42ab-a15b-b30ed4f2c5da','Bar Hemingway','bar',48.8688063,2.3276317,'38 Rue Cambon, 75001 Paris',4.5,781,1,['chic','intimiste','historique'],['jazz','piano'],[]),
  _p('60d4d296-fa21-45f5-b5d4-3d72cd4d3f87','Bar Hemingway (Ritz)','bar',48.8681,2.3284,'15 Place Vendome, 75001 Paris',4.6,1200,4,['chic','business','intimiste'],['jazz'],['speakeasy','cocktails'],true),
  _p('b613c088-ed31-4f87-86c3-40f5ac1465be','Bisou','bar',48.8615,2.3672,'15 Boulevard du Temple, 75003 Paris',4.5,980,2,['branché','intimiste'],['soul'],['cocktails']),
  _p('4d5b721e-948f-4887-9dde-9dc7fcf2a2b2','Candelaria','bar',48.8627,2.3661,'52 Rue de Saintonge, 75003 Paris',4.4,2100,3,['branché','animé'],['latino','house'],['speakeasy','cocktails','mexicain']),
  _p('5b0fece3-5c56-49cc-8b09-945a87cb75ca','Doris Bar','bar',48.8721685,2.2948131,'5 Rue de Presbourg, 75016 Paris',4.6,1160,1,['chic','feutré','intimiste'],['jazz','lounge'],[]),
  _p('c6c56352-c882-4c38-b9f8-45a73cf67de9','Experimental Cocktail Club','bar',48.8662,2.3486,'37 Rue Saint-Sauveur, 75002 Paris',4.4,1750,3,['animé','branché'],['house','funk'],['cocktails','speakeasy']),
  _p('9e53bc35-27d2-49bd-b2b0-4b73b5167556','Gentlemen 1919','bar',48.870978,2.311558,'11 Rue Jean Mermoz, 75008 Paris',4.8,48,4,['raffine','feutre','chic'],['lounge','jazz'],['cigar lounge','cocktails','cafe'],true),
  _p('a42a8885-1551-480c-8899-1debca066827','Hanami Teatime','bar',48.8641808,2.3556427,'50 Rue des Gravilliers, 75003 Paris',4.4,2495,1,['coloré','instagrammable','cosy'],[],['salon-de-thé','pancakes-japonais','quartier-Arts-et-Métiers']),
  _p('41ce3f42-6bab-45af-bfa6-79c91db8332e','HUBSY café & coworking','bar',48.8657505,2.3543291,'9bis Rue Lucien Sampaix, 75010 Paris',4.7,497,1,['calme','studieux','cosy'],[],['coffee-shop','coworking','quartier-Arts-et-Métiers']),
  _p('1138025d-ab2f-4784-b240-cc525f5b1518','Immersion République - Brunch & Coffee','bar',48.8710353,2.3601607,'8 Rue Lucien Sampaix 8-10, 75010 Paris',4.7,8426,2,['chic','convivial','tendance'],[],['brunch','coffee-shop','quartier-République']),
  _p('eff94ad6-46c2-4906-9c57-f2e3afe10d6a','Lavomatic','bar',48.8684697,2.3618697,'30 Rue René Boulanger, 75010 Paris',4.1,2114,1,['festif','intimiste','décontracté'],['pop','funk'],[]),
  _p('5c63b34d-3edc-4c95-88d4-0e718bb161c4','Le Bar du Plaza Athenee','bar',48.8662,2.3036,'25 Avenue Montaigne, 75008 Paris',4.5,880,4,['chic','romantique','business'],['lounge'],['cocktails'],true),
  _p('bd69a6a4-2e27-4b50-a897-3e9232beb35a','Le Comptoir General','bar',48.8704,2.3672,'80 Quai de Jemmapes, 75010 Paris',4.3,5600,2,['festif','décontracté','insolite'],['afro','house'],['terrasse','cocktails']),
  _p('96fb0c2a-2c4b-4056-9c3b-cb09dc84d24c','Le M. Musée du Vin','bar',48.8575815,2.2846249,'5 Square Charles Dickens, 75016 Paris',4.3,595,1,['historique','intimiste','romantique'],[],[]),
  _p('fa45ab9c-4804-4609-a7b6-70d8b30bd66a','Le Marilyn','bar',48.866147,2.379767,'122 Rue Oberkampf, 75011 Paris',4.6,312,2,['festif','convivial','branche'],['RnB','hip-hop'],['bar dansant','terrasse','privatisable']),
  _p('3392dc72-4fde-4283-9f30-154484feaf64','Le Perchoir Marais','bar',48.8629,2.364,'33 Rue de la Verrerie, 75004 Paris',4.5,1820,3,['chic','festif','branché'],['house','lounge'],['rooftop','cocktails','vue Tour Eiffel']),
  _p('e3f99b64-e3ba-4862-b532-b95cb8839da2','Le Perchoir Menilmontant','bar',48.8668,2.3897,'14 Rue Crespin du Gast, 75011 Paris',4.3,6100,3,['festif','branché'],['house','lounge'],['rooftop','terrasse','cocktails','vue Tour Eiffel']),
  _p('f45c268d-2707-49bb-843c-a64fb0bfad87','Le Saloon Far West','bar',48.8507948,2.3840419,'3 Rue Faidherbe, 75011 Paris',4.7,4383,1,['festif','convivial','western'],['pop','rick','DJ'],['bar-à-cocktails','pub','quartier-Faidherbe']),
  _p('93a66bdb-4647-4199-92a8-ad06703b744d','Le Syndicat','bar',48.8718,2.353,'51 Rue du Faubourg Saint-Denis, 75010 Paris',4.5,1300,3,['branché','intimiste'],['soul','funk'],['cocktails','speakeasy']),
  _p('64e18eed-85d6-4823-b18c-9f962ca91a1c','Little Red Door','bar',48.8632,2.3622,'60 Rue Charlot, 75003 Paris',4.7,940,3,['chic','intimiste'],['jazz','lounge'],['speakeasy','cocktails']),
  _p('17446c08-7e99-4044-9539-6f1351409962','Maison Souquet','bar',48.8836485,2.3314562,'10 Rue de Bruxelles, 75009 Paris',4.8,804,1,['romantique','sensuel','feutré'],['lounge','jazz'],[]),
  _p('bf465ccc-9ff0-4266-b9b4-129606c9eb72','Meisia : Bar à jeux & Boutique','bar',48.8694148,2.3569627,'84 Rue René Boulanger, 75010 Paris',4.3,17849,1,['ludique','convivial','décontracté'],[],['bar-à-jeux','boutique','quartier-République']),
  _p('d0e7b89d-8ad7-45f7-a7be-b5ca8af1faa0','Moonshiner','bar',48.8556969,2.3712084,'5 Rue Sedaine, 75011 Paris',4.5,2713,1,['intimiste','vintage','feutré'],['jazz','swing'],[]),
  _p('49b03f1b-7969-462b-9fed-5dd421cfba4e','Rosa Bonheur','bar',48.88,2.383,'2 Allee de la Cascade, 75019 Paris',4.2,6200,2,['festif','familial','décontracté'],['pop','latino'],['terrasse','jardin']),
  _p('5529da4b-2a69-4a38-8155-ae56f5ace729','Rosa Bonheur sur Seine','bar',48.8633432,2.3155056,'2 Port des Invalides, 75007 Paris',3.9,7526,1,['festif','décontracté','convivial'],['pop','disco','dj set'],[]),
  // ===================== RESTAURANTS =====================
  _p('27755316-f8da-4948-a90f-f21f4302f7d1','Auberge Nicolas Flamel','restaurant',48.8635423,2.3531534,'51 Rue de Montmorency, 75003 Paris',4.6,2017,1,['historique','intimiste','gastronomique'],[],[]),
  _p('077ee595-5922-4371-90a5-c96da897bea6','Bioburger Gobelins','restaurant',48.833764,2.3535511,'54 Av. des Gobelins, 75013 Paris',4.4,1613,1,['décontracté','éco-responsable','familial'],[],['burger-bio','fast-food','quartier-Gobelins']),
  _p('7100735f-35dc-41a0-9060-858edfa1cf49','Bonnie','restaurant',48.8499783,2.3625138,'10 Rue Agrippa d\'Aubigné, 75004 Paris',4.1,3822,1,['festif','branché','chic'],['house','dj set'],[]),
  _p('5d23dc58-f635-4533-a10f-425e1e1e6316','Bouillon Pigalle','restaurant',48.8823,2.3375,'22 Boulevard de Clichy, 75018 Paris',4.4,14800,1,['festif','familial','décontracté'],['pop'],['bistrot','brunch']),
  _p('971b606f-5a86-4206-98c4-21b81566044e','Brasserie de la Tour Eiffel','restaurant',48.860333,2.295613,'2 Av. de la Bourdonnais, 75007 Paris',4.1,657,2,['chaleureux','convivial','classique'],['soft'],['brasserie','pres Tour Eiffel','terrasse']),
  _p('ccdc42f0-3b3f-479f-9f53-eade926c3762','Breizh Cafe','restaurant',48.8593,2.3637,'109 Rue Vieille du Temple, 75003 Paris',4.4,9100,2,['cosy','familial'],['pop'],['crêperie']),
  _p('f13b4af3-0619-48ab-871a-b4670d557482','Café Laurent','restaurant',48.8547358,2.3395366,'33 Rue Dauphine, 75006 Paris',4.8,804,1,['feutré','historique','romantique'],['jazz'],[]),
  _p('41cd0ee8-9668-4a85-a036-34b80cd2d750','Candelaria','restaurant',48.8629825,2.3640307,'52 Rue de Saintonge, 75003 Paris',4.4,3079,1,['festif','convivial','branché'],['latino','dj set'],[]),
  _p('57b1429b-e1cf-4f14-a549-997b40406eba','Dalmata Paris 2','restaurant',48.8645246,2.3494238,'8 Rue Tiquetonne, 75002 Paris',4.6,5189,1,['convivial','chaleureux','branché'],[],['pizzeria','italien','quartier-Montorgueil']),
  _p('3d09d6f6-9a61-44c8-b998-c25eb0a14a40','Dans le Noir','restaurant',48.86521,2.34791,'51 Rue Quincampoix, 75004 Paris',4.4,2500,1,['dark','immersive'],['lounge'],[]),
  _p('576a28e3-b3bb-4cbf-a517-2e9d3a20bea4','Derrière','restaurant',48.864518,2.354208,'69 Rue des Gravilliers, 75003 Paris',4.2,2012,1,['intimiste','bohème','convivial'],['lounge','éclectique'],[]),
  _p('3798f5b0-c112-47a3-abfc-b9286e77495a','Derrière','restaurant',48.86351,2.36571,'69 Rue des Gravilliers, 75003 Paris',4.3,1300,1,['secret room','home vibe'],['chill'],[]),
  _p('11bab4a2-10ec-4c54-8b7f-875aad17746f','Ducasse sur Seine','restaurant',48.8605363,2.2918296,'19 Port Debilly, 75116 Paris',4.7,2164,1,['romantique','chic','gastronomique'],[],[]),
  _p('29e4d638-5022-4b13-8114-cdd220f280ca','East Mamma','restaurant',48.8519,2.3782,'133 Rue du Faubourg Saint-Antoine, 75011 Paris',4.4,11200,2,['animé','familial','festif'],['pop'],['italien','pizza']),
  _p('fc3b377c-ab08-4ed8-8959-4dab6efee47b','Girafe','restaurant',48.8630338,2.2885823,'1 Place du Trocadéro, 75016 Paris',4.4,5548,1,['chic','festif','branché'],['lounge','dj set'],[]),
  _p('c2cfbcd8-dbf8-49e8-87a9-b47bf3ab95a6','Hanok','restaurant',48.8651018,2.2937604,'6 Place d\'Iéna, 75116 Paris ',4.4,5548,1,['paisible','dépaysant','élégant'],[],[]),
  _p('05565222-c4cc-42dd-9aa5-0c2ad2914b58','Jungle Palace by Ephemera','restaurant',48.8748014,2.35665,'12 Rue de la Fidélité, 75010 Paris',4.8,21414,2,['exotique','festif','instagrammable'],['lounge','DJ'],['restaurant-bar','jungle','quartier-Gare-de-l\'Est']),
  _p('9421d19e-d2d3-44e9-bec4-a412750c2bf5','Kodawari Ramen','restaurant',48.853,2.336,'29 Rue Mazarine, 75006 Paris',4.4,4100,2,['décontracté','animé','insolite'],['pop'],['japonais']),
  _p('7c30c9fc-6486-4bf0-a6e1-7eda0c4653a6','Kodawari Ranen (Tsukiji)','restaurant',48.8546339,2.3381036,'12 Rue de Richelieu, 75001 Paris',4.4,12299,2,['authentique','immersif','animé'],[],['ramen','japonais','quartier-Odéon']),
  _p('515a5a31-f8fa-4543-8cd3-d36b79e3d1c8','La Felicita','restaurant',48.83343,2.371874,'5 Parv. Alan Turing, 75013 Paris',4.5,433,2,['festif','branche','immense'],['DJ'],['food court italien','ancienne gare','groupe']),
  _p('e16f9f92-5c08-463e-b6bc-e25717543c63','La Halle aux Grains','restaurant',48.8629365,2.3423588,'2 Rue de Viarmes, 75001 Paris ',4.3,881,1,['chic','élégant','gastronomique'],[],[]),
  _p('dd6e6fe7-ab4a-4234-a609-485da1a6a5b0','La Recyclerie','restaurant',48.89491,2.33721,'83 Boulevard Ornano, 75018 Paris',4.4,4500,1,['eco','casual'],['chill'],[]),
  _p('26d1d5fb-61e5-48d5-911b-4b1c08fcc131','La Tour d\'Argent','restaurant',48.849856,2.354994,'15 Quai de la Tournelle, 75005 Paris',4.6,808,1,['chic','romantique','gastronomique'],[],[]),
  _p('c54a3560-691e-47ab-87bd-3ca16832d687','Lapérouse','restaurant',48.8551202,2.3415552,'51 Quai des Grands Augustins, 75006 Paris',4.4,2120,1,['romantique','historique','intimiste'],['jazz','piano'],[]),
  _p('86259d9d-7ba5-455a-be09-6a112214ce81','Le Café des Chats','restaurant',48.8558739,2.371819,'9 Rue Sedaine, 75011 Paris',4.3,7040,1,['cosy','insolite','nostalgique'],[],['bar-à-chats','salon-de-thé','quartier-Bastille']),
  _p('0c07d31f-9eb1-45db-9f84-3ffd920314bd','Le Coupe-Chou','restaurant',48.8485228,2.3462711,'11 Rue de Lanneau, 75005 Paris',4.6,2483,1,['romantique','intimiste','historique'],[],[]),
  _p('9c12b464-d2d4-42ba-90c6-1cb49b2c4c71','Le Jules Verne','restaurant',48.8583698,2.2944833,'2e étage Tour Eiffel, Av. Gustave Eiffel, 75007 Paris',4.4,3588,1,['chic','romantique','gastronomique'],[],[]),
  _p('f5a18bbc-8731-4ba7-abe9-ced844779351','Le Jules Verne','restaurant',48.8582,2.2945,'Tour Eiffel Avenue Gustave Eiffel, 75007 Paris',4.5,2200,4,['chic','romantique','business'],['lounge'],['gastronomique','vue Tour Eiffel'],true),
  _p('d5fee0e0-c331-42b0-afd0-004574a54a00','Le Tout-Paris','restaurant',48.8585,2.347,'Cheval Blanc 8 Quai du Louvre, 75001 Paris',4.5,880,4,['chic','romantique'],['lounge'],['gastronomique','rooftop','vue Tour Eiffel'],true),
  _p('84fc1636-d0d6-4e48-8490-9a747ff6ef3f','Le Train Bleu','restaurant',48.8448989,2.3732694,'Gare de Lyon, Place Louis-Armand, 75012 Paris',4.4,18363,1,['chic','historique','élégant'],[],[]),
  _p('b0f0c7f6-f497-4116-8a45-5e1895e0b9dd','Les Ombres','restaurant',48.86178,2.29869,'27 Quai Jacques Chirac, 75007 Paris',4.1,358,3,['chic','romantique','spectaculaire'],['lounge'],['vue Tour Eiffel','rooftop musee','terrasse'],true),
  _p('b00ad27e-b321-4efa-b842-46d0f8c3849a','Les Ombres','restaurant',48.86178,2.29869,'27 Quai Jacques Chirac, 75007 Paris',4.1,3270,1,['romantique','élégant','gastronomique'],[],[]),
  _p('538d134a-da2f-405f-bc14-e1276715393c','Liza','restaurant',48.8676,2.3399,'14 Rue de la Banque, 75002 Paris',4.4,2300,3,['cosy','romantique'],['lounge','latino'],['libanais']),
  _p('6c4abe63-f36e-44a1-a9a8-ff0802186700','Monsieur Bleu','restaurant',48.8643563,2.2968759,'20 Av. de New York, 75116 Paris ',4.7,3987,1,['chic','élégant','branché'],['lounge'],[]),
  _p('63ab43fa-8fdd-4e1a-8385-513064462011','Père et Fish','restaurant',48.875682,2.3481175,'67 Rue du Faubourg Poissonnière, 75009 Paris',4.6,5227,1,['décontracté','moderne','convivial'],[],['fish-burger','fish-and-chips','quartier-Poissonnière']),
  _p('3e9e8ac5-b2c4-418c-b63b-e6d1c0e6e7f3','Pink Mamma','restaurant',48.8819469,2.3345309,'20bis Rue de Douai, 75009 Paris',4.7,50067,1,['festif','branché','convivial'],['pop','italo'],[]),
  _p('b8365e2f-5085-4944-8080-d4110a449357','Pink Mamma','restaurant',48.87941,2.33721,'20 Avenue Trudaine, 75009 Paris',4.5,5000,1,['instagrammable','cozy'],['chill'],[]),
  _p('95e5778c-6638-4340-85dd-c666a07c08ac','Pink Mamma','restaurant',48.8819,2.3375,'20bis Rue de Douai, 75009 Paris',4.5,13900,3,['branché','animé'],['pop','soul'],['italien','terrasse'],true),
  _p('ef29d828-e955-425a-8c00-359072011765','Soon Grill Le Marais 순그릴 마레','restaurant',48.858096,2.367436,'78 Rue des Tournelles, 75003 Paris',4.5,3082,3,['chaleureux','minimaliste','convivial'],[],['barbecue-coréen','wine-bar','quartier-Marais']),
  _p('91b75131-7216-4cf6-bbad-7eeda9bea246','Sphere','restaurant',48.874267,2.316939,'18 Rue La Boetie, 75008 Paris',4.8,974,4,['gastronomique','raffine','elegant'],['soft'],['haute cuisine','menu degustation','mocktails'],true),
  _p('9fb4e658-e464-4406-9429-1efdacebe70d','Wagon Bleu','restaurant',48.88351,2.31571,'7 Rue Boursault, 75017 Paris',4.4,1400,1,['corsican','vintage'],['lounge'],[]),
  // ===================== HOTELS =====================
  _p('c63fe33f-c3ab-4440-89db-866c46d6e8a6','Bloom House Hotel & Spa','hotel',48.881494,2.362626,'23 R. du Chateau Landon, 75010 Paris',4.6,711,3,['cosy','verdoyant','relax'],['soft'],['jardin','spa piscine','cocktail bar']),
  _p('44536cb5-1a1d-40a5-acac-0674fbfc2c4c','Brach Paris','hotel',48.8636,2.282,'1-7 Rue Jean Richepin, 75116 Paris',4.6,1400,4,['branché','chic','cosy'],['lounge','soul'],['design','rooftop'],true),
  _p('ed5cea5e-eee1-4a6f-a2fd-1765817ea1f8','Chateau des Fleurs','hotel',48.871826,2.298396,'19 Rue Vernet, 75008 Paris',4.7,320,4,['fleuri','charmant','raffine'],['soft'],['boutique-hotel','pres Champs-Elysees','lounge'],true),
  _p('162db586-2b60-4181-ac9e-a55ebc26992e','Chateau Voltaire','hotel',48.867112,2.33328,'55 Rue Saint-Roch, 75001 Paris',4.6,179,4,['design','cosy','raffine'],['lounge'],['boutique-hotel','bar','quartier Saint-Honore'],true),
  _p('33922c30-b334-4998-9f50-c9b4b1e3f506','Four Seasons George V','hotel',48.8686,2.3008,'31 Avenue George V, 75008 Paris',4.8,4100,4,['chic','romantique','business'],['lounge'],['palace'],true),
  _p('7a7e566e-3cfc-4a9d-b733-6ed515625736','Generator Paris','hotel',48.8809,2.37,'9-11 Place du Colonel Fabien, 75010 Paris',4.1,6400,2,['festif','décontracté','business'],['house','pop'],['rooftop','vue Tour Eiffel']),
  _p('58d2511a-7418-4ad2-ab04-89c2348e4681','Hotel Costes','hotel',48.8676,2.3274,'239 Rue Saint-Honore, 75001 Paris',4.4,1800,4,['chic','festif'],['lounge','house'],['palace','terrasse'],true),
  _p('51c56a0b-3bdf-464f-86f3-ce191ce64641','Hotel Dame des Arts','hotel',48.852847,2.342293,'4 Rue Danton, 75006 Paris',4.7,331,4,['design','chic','elegant'],['lounge'],['rooftop vue Tour Eiffel','terrasse','Rive Gauche'],true),
  _p('ccc8cbdd-72dd-43d1-8ca6-19e286369706','Hotel Grand Amour','hotel',48.8714,2.355,'18 Rue de la Fidelite, 75010 Paris',4.3,1100,3,['cosy','festif','branché'],['pop','afro'],['boutique-hôtel','design','terrasse']),
  _p('0fcd95c1-9654-4263-88f8-b92e32e3ffca','Hotel Madame Reve','hotel',48.864535,2.342873,'48 Rue du Louvre, 75001 Paris',4.6,665,4,['design','romantique','sexy'],['lounge'],['ancien hotel des postes','rooftop','sauna'],true),
  _p('3b375410-bf0f-4a90-903b-a071e50c3454','Hotel Marignan Champs-Elysees','hotel',48.868532,2.306548,'12 Rue de Marignan, 75008 Paris',4.7,521,4,['chaleureux','elegant','intime'],['soft'],['boutique-hotel','vue Tour Eiffel','Champs-Elysees'],true),
  _p('6643699b-a23d-4391-96e7-0cb0acbbc16c','Hotel National des Arts et Metiers','hotel',48.865717,2.353225,'243 Rue Saint-Martin, 75003 Paris',4.4,318,3,['design','branche','elegant'],['lounge'],['rooftop','bar','Marais']),
  _p('e702ef78-41ac-45cd-a894-ed5835e4a4cc','Hôtel Pont Royal Paris','hotel',48.856686,2.327746,'3 Rue de Montalembert, 75007 Paris',4.7,301,3,['raffiné','littéraire','élégant'],['jazz'],['hôtel-5-étoiles','bar-jazz','quartier-Saint-Germain'],true),
  _p('127f6df1-7865-4d3a-a2c1-7a0ef0e67516','Hôtel Pullman Paris Montparnasse','hotel',48.838455,2.320393,'19 Rue du Commandant René Mouchotte, 75014 Paris',4.8,15646,2,['moderne','design','vue-panoramique'],['lounge','DJ'],['hôtel-4-étoiles','sky-bar','rooftop','quartier-Montparnasse'],true),
  _p('358ce5ab-6bd9-4c43-a50c-8ddf5333cc91','Hôtel Westminster','hotel',48.869373,2.331062,'13 Rue de la Paix, 75002 Paris',4.0,821,3,['classique','historique','luxe'],['jazz','lounge'],['hôtel-5-étoiles','bar','quartier-Opéra'],true),
  _p('c451f11e-98fd-4728-9eb4-fbf6178fc08c','Hôtel Whistler Paris - 10e arrondissement','hotel',48.8793055,2.3559889,'36 Rue de Saint-Quentin, 75010 Paris',4.5,622,1,['thématique','insolite','cosy'],['lounge'],['hôtel-boutique','bar','quartier-Gare-du-Nord']),
  _p('b6a789b4-71ad-42c1-95a7-c891c9875741','Le Bristol Paris','hotel',48.8721,2.3157,'112 Rue du Faubourg Saint-Honore, 75008 Paris',4.8,2600,4,['chic','romantique','business'],['lounge'],['palace','jardin'],true),
  _p('7c69c842-747c-42d8-a400-3f76d4290bfa','Le Grand Mazarin','hotel',48.8577,2.3545,'6 Rue des Archives, 75004 Paris',4.5,1800,3,['chic','romantique','cosy'],['lounge','jazz'],['boutique-hôtel','design']),
  _p('33f5dc5d-acef-4306-9132-a21795b6b1ee','Le Meurice','hotel',48.8654,2.3281,'228 Rue de Rivoli, 75001 Paris',4.7,2900,4,['chic','business'],['lounge'],['palace'],true),
  _p('004a013a-b26a-4644-8d60-feac066b395e','Le Pavillon de la Reine','hotel',48.8556,2.3661,'28 Place des Vosges, 75003 Paris',4.7,950,4,['romantique','chic','intimiste'],['lounge'],['boutique-hôtel','jardin']),
  _p('c7ea09b7-5d4a-4422-af25-a58c3c6c45bf','Maison Proust Hotel & Spa','hotel',48.864092,2.363236,'26 Rue de Picardie, 75003 Paris',4.8,284,4,['luxueux','romantique','feutre'],['lounge'],['inspiration Proust','spa La Mer','Marais'],true),
  _p('9cbfb3a4-ec61-4ecf-96ae-64cc427ce23d','Mama Shelter Paris East','hotel',48.8676,2.4053,'109 Rue de Bagnolet, 75020 Paris',4.2,3900,2,['festif','décontracté','familial'],['afro','house'],['rooftop','design']),
  _p('550df4b4-9132-4f73-b06d-cea20cfb9914','OFF Paris Seine','hotel',48.8388,2.3736,'20-22 Port Austerlitz, 75013 Paris',4.2,2200,3,['insolite','branché','romantique'],['lounge','house'],['péniche','design','terrasse']),
  _p('9326a4a8-c832-4f1a-aab3-2552ca9ed5ac','Pullman Paris Centre Bercy','hotel',48.831625,2.386782,'1 Rue de Libourne, 75012 Paris',4.6,8026,2,['moderne','spa','confort'],['lounge'],['hôtel-4-étoiles','piscine-spa','quartier-Bercy'],true),
  _p('5fc6d628-3c1a-4ea2-adf9-8d8bf9e4e385','Pullman Paris Tour Eiffel','hotel',48.855649,2.292858,'18 Avenue De Suffren, 22 Rue Jean Rey Entrée Au, 75015 Paris',4.6,15614,4,['moderne','élégant','vue-Tour-Eiffel'],['lounge','DJ'],['hôtel-4-étoiles','bar','vue-Tour-Eiffel','quartier-Champ-de-Mars'],true),
  _p('41e2aa41-d050-4864-80ef-77d53c6ad7d4','Ritz Paris','hotel',48.8681,2.3284,'15 Place Vendome, 75001 Paris',4.8,3600,4,['chic','romantique','business'],['lounge'],['palace','jardin'],true),
  _p('28c8e646-e2f6-42e1-84c8-4db7764f38b1','SO/ Paris','hotel',48.852,2.361,'10 Rue Agrippa d Aubigne, 75004 Paris',4.5,1800,4,['branché','festif','chic'],['house','lounge'],['rooftop','design','vue Tour Eiffel'],true),
  _p('7bf1fa72-668c-408d-be8e-3c44f149506d','Sourire Boutique Hotel','hotel',48.85503,2.275528,'29 Rue des Marronniers, 75016 Paris',4.7,108,3,['charmant','familial','chaleureux'],['soft'],['hotel particulier','terrasse rooftop','petit-dejeuner']),
  _p('540521ac-843e-4c4a-a146-7f766a3d3c0b','The Hoxton Paris','hotel',48.8688,2.3506,'30-32 Rue du Sentier, 75002 Paris',4.4,3200,3,['branché','cosy','business'],['house','soul'],['boutique-hôtel','design']),
  _p('6218ac00-de49-41f3-b4a4-c5aa00a2fd35','Villa des Pres','hotel',48.853485,2.336409,'29 Rue de Buci, 75006 Paris',4.6,108,4,['luxueux','raffine','elegant'],['soft'],['boutique-hotel','spa sauna','art deco'],true),
  _p('e7e161e5-c46c-4c5a-a322-8fdb379a0ea0','Zoku Paris','hotel',48.895894,2.311326,'48 Av. de la Prte de Clichy, 75017 Paris',4.6,855,2,['design','convivial','cosy'],['lounge'],['aparthôtel','coworking','rooftop','quartier-Clichy-Batignolles']),
  // ===================== ROOFTOPS =====================
  _p('ff9d7528-b76d-4d3b-b275-b50c1c9e6e2d','10eme Ciel','rooftop',48.855512,2.292716,'18 Av. de Suffren, 75015 Paris',4.1,566,3,['chic','festif','branche'],['DJ'],['vue Tour Eiffel','Pullman','cocktails']),
  _p('7697cd0a-5a51-4116-8212-13a367bebab9','Gigi Rooftop','rooftop',48.87112,2.33191,'15 Rue de la Paix, 75002 Paris',4.5,900,1,['italian','luxury'],['lounge'],[]),
  _p('97d7089c-3bbd-4334-adec-20c0835c00e8','Ilvolo Bar Rooftop','rooftop',48.839935,2.303228,'257 Rue de Vaugirard, 75015 Paris',4.4,779,2,['chic','romantique','convivial'],['lounge'],['vue Tour Eiffel','cocktails dauteur']),
  _p('9cdc2bc3-db21-407e-b3c4-20a077eba6f6','L\'Oiseau Blanc Peninsula','rooftop',48.8686,2.2964,'19 Avenue Kleber, 75016 Paris',4.7,2400,4,['chic','romantique','business'],['lounge'],['rooftop','vue Tour Eiffel','gastronomique','palace'],true),
  _p('ec804971-b3ee-4ae3-97ab-60ad657d8f53','Perruche','rooftop',48.87339,2.32652,'Printemps Haussmann, 2 Rue du Havre, 75009 Paris',4.3,1500,1,['chic','sunset'],['lounge'],[]),
  _p('cb181f75-81be-42b3-84a3-98bb8e0ca6f3','Rooftop Dame des Arts','rooftop',48.8528666,2.3422929,'4 Rue Danton, 75006 Paris',4.3,727,1,['chic','intimiste','romantique'],['lounge','deep house'],[]),
  _p('343441a2-3e1a-462b-b9a5-816fb8ed01eb','Rooftop du Printemps Haussmann','rooftop',48.8738,2.3316,'64 Boulevard Haussmann, 75009 Paris',4.3,18000,1,['animé','décontracté','familial'],[],['rooftop','vue panoramique','vue Tour Eiffel','gratuit']),
  _p('77901f33-3712-4496-8100-44fd686a1f2a','Rooftop Nijinsky','rooftop',48.857703,2.346822,'1 Pl. du Chatelet, 75001 Paris',4.3,78,3,['chic','central','branche'],['lounge'],['terrasse','vue toits de Paris']),
  _p('69de4f46-3e04-4103-a065-006726c65f91','Rooftop Villa M','rooftop',48.842378,2.312452,'28 Bd Pasteur, 75015 Paris',3.9,207,3,['chic','romantique','vegetal'],['lounge'],['vue Tour Eiffel','facade vegetale','coucher de soleil']),
  _p('248dcabe-0db1-46c0-a5f7-d3a73a9896a5','Terraza Mikuna','rooftop',48.857333,2.354002,'1 Rue des Archives, 75004 Paris',3.9,892,3,['chic','branche','romantique'],['lounge'],['vue Marais','cuisine peruvienne','coucher de soleil']),
  _p('acace5f4-8c76-4c7c-b09d-8daed56e5ef9','TOO TacTac','rooftop',48.82547,2.382415,'65 Rue Bruneseau, 75013 Paris',4.1,329,3,['festif','glamour','branche'],['DJ'],['27e etage','vue panoramique','cocktails'],true),
  // ===================== PARCS =====================
  _p('15ebc994-7e34-468b-b36c-0d9d2c88d304','Coulee Verte Rene-Dumont','parc',48.849455,2.371486,'Coulee Verte Rene-Dumont, 75012 Paris',4.6,683,1,['insolite','romantique','verdoyant'],['aucun'],['promenade plantee','ancien viaduc','balade']),
  _p('110a2dd0-e2f1-40a2-a17d-651f4a7f6012','Jardin alpin (Jardin des Plantes)','parc',48.8439069,2.359658,'57 Rue Cuvier, 75005 Paris',4.5,727,1,['paisible','nature','romantique'],[],[]),
  _p('06bfc1cf-eb70-4405-9477-9dc137ff57fd','Jardin de la Nouvelle France','parc',48.865083,2.310609,'Av. Franklin Delano Roosevelt, 75008 Paris',4.7,39,1,['romantique','cache','intime'],['aucun'],['jardin secret','cascade','1900']),
  _p('b1c16fe7-7bb5-483f-88c7-a7b8b0275c8b','Jardin du Luxembourg','parc',48.846614,2.336331,'75006 Paris',4.7,938,1,['romantique','emblematique','verdoyant'],['aucun'],['bassin','statues','chaises vertes']),
  _p('d19928dd-e017-4474-8db4-b36905e14001','Parc de Bercy','parc',48.83706,2.378902,'128 Quai de Bercy, 75012 Paris',4.0,543,1,['paisible','verdoyant','familial'],['aucun'],['jardins thematiques','passerelles','peu touristique']),
  _p('6bf9b077-5e9f-48f0-b2cc-6c20d79884bb','Parc des Buttes-Chaumont','parc',48.88095,2.382761,'1 Rue Botzaris, 75019 Paris',4.6,761,1,['romantique','sauvage','spectaculaire'],['aucun'],['falaises','lac','temple belvedere']),
  _p('171f3bd6-073c-41d4-8952-f81c1ddefd62','Parc Floral de Paris','parc',48.837702,2.444298,'Rte de la Pyramide, 75012 Paris',4.5,898,1,['nature','familial','verdoyant'],['aucun'],['jardin botanique','papillons','aires de jeux']),
  _p('26d96505-1716-46fe-93c7-a03857e02ea1','Parc Monceau','parc',48.879684,2.308955,'35 Bd de Courcelles, 75008 Paris',4.6,963,1,['romantique','verdoyant','calme'],['aucun'],['colonnades','statues','plan deau']),
  _p('fd85718d-16bd-4406-bfee-ac69ac2c5c47','Parc Montsouris','parc',48.822672,2.33766,'2 Rue Gazan, 75014 Paris',4.6,721,1,['paisible','verdoyant','familial'],['aucun'],['vallonne','lac','allees boisees']),
  _p('d8340397-a6ca-47a2-b7f8-590a864c1aaf','Square des Batignolles','parc',48.8875,2.316479,'144bis Rue Cardinet, 75017 Paris',4.5,841,1,['romantique','paisible','verdoyant'],['aucun'],['style paysager','lac','cascade']),
  _p('1f452fd7-06b0-4f68-bce0-63ca5ade35bc','Square du Vert-Galant','parc',48.857487,2.3401677,'15 Place du Pont Neuf, 75001 Paris',4.5,1539,1,['romantique','paisible'],[],[]),
  _p('2aca08e4-3bcb-4214-a741-ab83c62488a1','Square Saint-Lambert','parc',48.842244,2.296935,'2 Rue Jean Formige, 75015 Paris',4.3,312,1,['familial','verdoyant','local'],['aucun'],['square','carrousel','aires de jeux']),
  // ===================== ADRESSES & SPOTS PHOTO =====================
  _p('27ea6453-4037-4cc0-86a1-7d32cd8bcb32','Arénes de Lutèce','adresse',48.845116,2.3528366,'49 Rue Monge, 75005 Paris',4.2,5726,1,['historique','paisible','insolite'],[],[]),
  _p('38a1e32e-2909-4fb4-b8d5-938d3b9d93c2','Atelier des Lumières','adresse',48.86191,2.37021,'38 Rue Saint-Maur, 75011 Paris',4.7,12000,1,['immersive','digital'],['ambient'],[]),
  _p('143078c7-f1ed-4a2b-a314-46f87737f8a8','Bercy Village','adresse',48.83284,2.386188,'28 Rue Francois Truffaut, 75012 Paris',4.4,934,1,['convivial','verdoyant','anime'],['aucun'],['village pave','anciens chais','boutiques']),
  _p('d9b87969-143a-441f-b9f7-081b3a8bde91','Bunker de la Gare de l\'Est','adresse',48.8768146,2.3591978,'Place du 11 Novembre 1918, 75010 Paris',4.7,595,1,['mystérieux','historique'],[],[]),
  _p('0fb257b6-dad3-42ee-9ce3-a5fdce63b417','Cité du Figuier','adresse',48.8659278,2.3785695,'Cité du Figuier, 75011 Paris',4.5,2034,1,['paisible','bucolique','caché'],[],[]),
  _p('a15000ca-6ee3-4b4a-b76c-e5185f057d84','Cité Florale','adresse',48.8227065,2.3453748,'Cité Florale, 75013 Paris',4.4,330,1,['bucolique','paisible','charmant'],[],[]),
  _p('2d191576-3161-4c6c-a2a5-d40e09a603a6','Deyrolle','adresse',48.8565331,2.3264245,'46 Rue du Bac, 75007 Paris',4.7,2115,1,['insolite','feutré','curieux'],[],[]),
  _p('53fa8672-16d5-46fd-a447-37b9d1020638','Galerie Véro-Dodat','adresse',48.8628173,2.3402386,'19 Rue Jean-Jacques Rousseau, 75001 Paris',4.4,493,1,['historique','élégant','calme'],[],[]),
  _p('9d009d7a-b247-4c5f-8b21-a71d5b1bd237','Librairie Galignani','adresse',48.865062,2.328547,'224 Rue de Rivoli, 75001 Paris',4.5,365,1,['raffine','historique','calme'],['aucun'],['librairie anglaise','boiseries 1930','Tuileries']),
  _p('95e60197-deeb-42d3-9f97-1c58b3a68493','Librairie Jousseaume','adresse',48.866961,2.339886,'45-47 Gal Vivienne, 75002 Paris',4.6,245,1,['historique','romantique','feutre'],['aucun'],['librairie 1826','Galerie Vivienne','livres anciens']),
  _p('10d4446b-8c55-4b45-9809-64183dfba808','Maison Loo (Pagode)','adresse',48.8767766,2.3077965,'48 Rue de Courcelles, 75008 Paris',4.2,330,1,['insolite','dépaysant','historique'],[],[]),
  _p('f8ad7490-db3e-4854-82a9-c0aea28a97ec','Musée Albert-Kahn','adresse',48.8412532,2.2284942,'2 Rue du Port, 92100 Boulogne-Billancourt',4.6,5113,1,['dépaysant','paisible','contemplatif'],[],[]),
  _p('05c41474-da88-4ee4-9741-6c931982ecee','Musée des Arts Forains','adresse',48.83391,2.38621,'53 Avenue des Terroirs de France, 75012 Paris',4.7,3000,1,['vintage','fairground'],['lounge'],[]),
  _p('7656b8a4-551b-490c-80c5-6871903f8fe4','Musée du cirque Bouglione','adresse',48.863308,2.367233,'110 Rue Amelot, 75011 Paris',4.3,5113,1,['nostalgique','insolite'],[],[]),
  _p('37878f40-bf8f-4481-9f66-ca6de8f482bc','Palais Garnier','adresse',48.87197,2.331601,'Pl. de l\'Opera, 75009 Paris',4.7,817,1,['spectaculaire','emblematique','feerique'],['aucun'],['opera','grand escalier','plafond Chagall']),
  _p('c3acac3c-1c55-4368-aac3-7f8a470b6f3c','Passage du Grand Cerf','adresse',48.864669,2.350091,'145 Rue St Denis, 75002 Paris',4.5,546,1,['raffine','artisanal','historique'],['aucun'],['haute verriere','createurs','1825']),
  _p('fe529d6f-f219-48be-8489-cedc6565f381','Passage secret rue des Anglais','adresse',48.850652,2.3475339,'Rue des Anglais, 75005 Paris',4.3,2115,1,['mystérieux','ludique'],[],[]),
  _p('e2fc9386-284d-4fe8-ba49-189f78450a14','Piscine Roger Le Gall (créneaux naturistes)','adresse',48.841751,2.4128012,'34 Bd Carnot, 75012 Paris',3.4,1584,1,['insolite','décontracté'],[],[]),
  _p('cf75678f-9d35-4e24-8d71-a1ecc4755e7d','Quartier de la Mouzaéa','adresse',48.8810751,2.3938225,'Quartier de la Mouzaéa, 75019 Paris',4.4,2017,1,['bucolique','paisible','romantique'],[],[]),
  _p('d8e62bd8-0c73-48b0-bbe3-305e8f5a7454','Shakespeare and Company','adresse',48.852563,2.34713,'37 Rue de la Bucherie, 75005 Paris',4.6,613,1,['mythique','romantique','feerique'],['aucun'],['librairie anglaise','face Notre-Dame','legendaire']),
  _p('c41b48ab-a1f1-401a-a842-7c81df0e9c2b','Temple Ganesh','adresse',48.8859431,2.3606865,'17 Rue Pajol, 75018 Paris',4.5,604,1,['spirituel','dépaysant','paisible'],[],[]),
];

Map<String, dynamic> _p(
  String id,
  String name,
  String type,
  double lat,
  double lon,
  String address,
  double rating,
  int reviewCount,
  int priceLevel,
  List<String> ambianceTags,
  List<String> musicTags,
  List<String> styleTags, [
  bool isPremium = false,
  String? websiteUrl,
]) =>
    {
      'id': id,
      'name': name,
      'type': type,
      'latitude': lat,
      'longitude': lon,
      'address': address,
      'rating': rating,
      'review_count': reviewCount,
      'price_level': priceLevel,
      'ambiance_tags': ambianceTags,
      'music_tags': musicTags,
      'style_tags': styleTags,
      'is_premium': isPremium,
      'website_url': ?websiteUrl,
    };
