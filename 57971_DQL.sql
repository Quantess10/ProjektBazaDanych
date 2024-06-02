-- Wybierz wszystkie samochody z wypożyczalni, których dostępność jest potwierdzona
SELECT * 
FROM AUTA 
WHERE DOSTEPNOSC = 'T';


-- Policz liczbę klientów wypożyczalni
SELECT COUNT(*) AS LICZBA_KLIENTOW 
FROM KLIENCI;


-- Wyszukaj wszystkie unikalne marki samochodów dostępnych w wypożyczalni
SELECT DISTINCT MARKA 
FROM AUTA;


-- Wyszukaj klientów, którzy nie podali swójego adresu e-mail
SELECT * 
FROM KLIENCI 
WHERE EMAIL IS NULL;


-- Wyszukaj pracowników wypożyczalni, którzy wymożyczyli więcej niż 5 samochodów
SELECT ID, IMIE, NAZWISKO 
FROM PRACOWNICY 
WHERE ILOSC_WYPOZYCZONYCH_AUT > 5;


-- Wyszukaj średnią ilość wypożyczonych samochodów przez pracownika
SELECT ROUND(AVG(ILOSC_WYPOZYCZONYCH_AUT), 0) AS SREDNIA_WYPOZYCZONYCH_AUT 
FROM PRACOWNICY;


-- Wybierz wszystkie samochody wypożyczone przez danego klienta
SELECT * 
FROM AUTA 
WHERE ID IN 
    (SELECT AUTO_ID FROM WYPOZYCZENIA WHERE KLIENT_ID = 5);


-- Wyszukaj klientów, którzy wypożyczyli co najmniej 3 samochody:
SELECT * 
FROM KLIENCI 
WHERE ID IN 
    (SELECT KLIENT_ID FROM WYPOZYCZENIA GROUP BY KLIENT_ID HAVING COUNT(*) >= 3);


-- Wyszukaj pracowników, którzy wypożyczyli więcej aut niż średnia liczba wypożyczonych aut przez wszystkich pracowników
SELECT * 
FROM PRACOWNICY 
WHERE ILOSC_WYPOZYCZONYCH_AUT > (SELECT AVG(ILOSC_WYPOZYCZONYCH_AUT) 
FROM PRACOWNICY);


-- Wyszukaj najczęściej wypożyczane modele samochodów w wypożyczalni
SELECT MODEL, COUNT(*) AS LICZBA_WYPOZYCZEN 
FROM WYPOZYCZENIA 
JOIN AUTA ON WYPOZYCZENIA.AUTO_ID = AUTA.ID 
GROUP BY MODEL 
ORDER BY LICZBA_WYPOZYCZEN DESC;