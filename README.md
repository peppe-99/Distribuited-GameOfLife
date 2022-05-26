# MPI-GameOfLife - PCPC Project
**Studente**: Giuseppe Cardaropoli

**Matricola**: 0522501310
 
**Project ID**: 01310 % 5 == 0

## Indice
* [Introduzione](#introduzione)
* [Istruzioni per l'esecuzione](#istruzioni-per-lesecuzione)
* [Descrizione della soluzione](#descrizione-della-soluzione)
* [Benchmarks](#benchmarks)
* [Analisi dei risultati](#analisi-dei-risultati)

## Introduzione
**The Game of Live**, anche conosciuto come **Life**, è un automa cellulare sviluppato dal matematico inglese John Conway alla fine degli anni sessanta. Lo scopo è quello di mostrare come comportamenti simili alla vita possono nascere da regole semplici e da interazioni tra diversi corpi. Ad esempio, alcuni pattern ricordano la riproduzione cellulare, altri il volo di un aliante e così via.
Si tratta di un "**gioco senza giocatori**" in quanto la sua evoluzione dipende dalla configurazione iniziale e non richiederà nessun input. Questo gioco si svolge su una griglia bidimensionale dove ogni cella può trovarsi in due possibili stati: **viva** o **morta**. Gli stati di tutte le celle in una data generazione sono usati per calcolare lo stato delle celle nella generazione successiva. Quindi, tutte le celle vengono aggiornate simultaneamente. La transizione di stato di una cella dipende dallo stato dei suoi vicini:
- Qualsiasi cella viva con meno di due celle vive adiacenti muore, come per effetto d'isolamento;
- Qualsiasi cella viva con due o tre celle vive adiacenti sopravvive alla generazione successiva;
- Qualsiasi cella viva con più di tre celle vive adiacenti muore, come per effetto di sovrappopolazione;
- Qualsiasi cella morta con esattamente tre celle vive aciacenti diventa una cella viva, come per effetto di riproduzione.

## Istruzioni per l'esecuzione
- **Compilazione**
```
mpicc -g distribuited-game-of-life.c -o distribuited-game-of-life
```
- **Esecuzione**: 
```
mpirun --allow-run-as-root -np <np> distribuited-game-of-life <row> <col> <num_gen>
```
Sostituisci:
- **np**: numero di processori;
- **row**: numero righe della matrice di gioco;
- **col**: numero colonne della matrice di gioco;
- **num_gen**: numero di generazioni.

## Descrizione della Soluzione
> **Assunzioni**: esistono diverse varianti del gioco. È stata considerata una matrice **non toroidale**. Quindi le celle ai bordi della matrice hanno 5 vicini, invece, quelle agli angoli solo 3. Inoltre, è stato deciso che il **master** costruibisce alla computazione.

Prima di iniziare il gioco vengono controllati i parametri dati in input dall'utente, riguardanti il numero di processori, grandezza della matrice e numero di generazioni. Successivamente vengono create tutte le strutture dati necessarie.

`matrix` è un array che rappresenta la matrice di gioco, il cui stato sarà inizializzato dal processo **master** in maniera pseudocasuale. La matrice di gioco è stata suddivisa per righe in maniera equa fra tutti i processi. La suddivisione viene effettuata con la funzione `MPI_Scatterv()` una volta aver calcolato i displacements e quanti elementi invare ad ogni processo.

Ogni processo avrà la prima e/o l'ultima riga della propria sottomatrice vincolate. Per questo motivo, all'inizio di ogni generazione avviene uno scambio non bloccante di righe tra processi vicini. Ogni processo tranne l'ultimo invia la propria ultima riga al processo successivo ed ogni processo tranne il primo invia la sua prima riga al processo precedente:
```c
if (rank > 0) {
	MPI_Isend(&process_matrix[0], col, MPI_INT, rank-1, rank-1, MPI_COMM_WORLD, &send_first_row);
	MPI_Irecv(top_row, col, MPI_INT, rank-1, rank, MPI_COMM_WORLD, &receive_prev_row);
}
if (rank < np-1) {
	MPI_Isend(&process_matrix[(local_row-1) * col], col, MPI_INT, rank+1, rank+1, MPI_COMM_WORLD, &send_last_row);
	MPI_Irecv(bottom_row, col, MPI_INT, rank+1, rank, MPI_COMM_WORLD, &receive_next_row);
}
```
Poi ogni processo inizia a calcolare lo stato delle righe non vincolate (se ci sono) tramite la funzione `update_not_chained_rows()`. Successivamente, viene calcolato lo stato delle righe vincolate. A questo punto possiamo trovarci in due situazioni:
1. la sottomatrice è composta da una sola riga. Quindi per calcolarne lo stato successivo sono necessarie sia la `top_row` che la `bottom_row`;
2. la sottomatrice è composta da almeno due righe. nella generazione successiva sono necessarie sia la che quindi è doppiamente vincolata.

**To be continued...**

## Benchmarks

## Analisi dei Risultati
``
