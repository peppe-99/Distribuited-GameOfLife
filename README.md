# MPI-GameOfLife - PCPC Project
**Studente**: Giuseppe Cardaropoli

**Matricola**: 0522501310
 
**Project ID**: 01310 % 5 == 0

## Indice
* [Introduzione](#introduzione)
* [Istruzioni per l'esecuzione](#istruzioni-per-lesecuzione)
	* [Compilazione](#compilazione)
	* [Esecuzione](#esecuzione)
* [Descrizione della soluzione](#descrizione-della-soluzione)
* [Correttezza](#correttezza)
* [Benchmarks](#benchmarks)
	* [Weak Scalability](#weak-scalability)
	* [Strong Scalability](#strong-scalability)
* [Analisi dei risultati](#analisi-dei-risultati)

## Introduzione
**The Game of Live**, anche conosciuto come **Life**, è un automa cellulare sviluppato dal matematico inglese John Conway alla fine degli anni sessanta. Lo scopo è quello di mostrare come comportamenti simili alla vita possono nascere da regole semplici e da interazioni tra diversi corpi. Ad esempio, alcuni pattern ricordano la riproduzione cellulare, altri il volo di un aliante e così via.
Si tratta di un "**gioco senza giocatori**" in quanto la sua evoluzione dipende dalla configurazione iniziale e non richiederà nessun input. Questo gioco si svolge su una griglia bidimensionale dove ogni cella può trovarsi in due possibili stati: **viva** o **morta**. Gli stati di tutte le celle in una data generazione sono usati per calcolare lo stato delle celle nella generazione successiva. Quindi, tutte le celle vengono aggiornate simultaneamente. La transizione di stato di una cella dipende dallo stato dei suoi vicini:
- Qualsiasi cella viva con meno di due celle vive adiacenti muore, come per effetto d'isolamento;
- Qualsiasi cella viva con due o tre celle vive adiacenti sopravvive alla generazione successiva;
- Qualsiasi cella viva con più di tre celle vive adiacenti muore, come per effetto di sovrappopolazione;
- Qualsiasi cella morta con esattamente tre celle vive aciacenti diventa una cella viva, come per effetto di riproduzione.

## Istruzioni per l'esecuzione
### Compilazione
```
mpicc -g distribuited-game-of-life.c -o distribuited-game-of-life
```
### Esecuzione 
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

Ogni processo avrà la prima e/o l'ultima riga della propria sottomatrice vincolate. Per questo motivo, all'inizio di ogni generazione avviene uno scambio non bloccante di righe tra processi vicini. Ogni processo tranne l'ultimo invia la propria ultima riga (`bottom_row`) al processo successivo ed ogni processo tranne il primo invia la sua prima riga (`top_row`) al processo precedente:
```c
if (rank > 0) {
	MPI_Isend(&process_matrix[0], col, MPI_INT, rank-1, rank-1, MPI_COMM_WORLD, &send_first_row);
	MPI_Irecv(top_row, col, MPI_INT, rank-1, rank, MPI_COMM_WORLD, &receive_prev_row);
}
if (rank < np-1) {
	MPI_Isend(&process_matrix[(local_row-1) * col], col, MPI_INT, rank+1, rank+1, MPI_COMM_WORLD, &send_last_row);
	MPI_Irecv(bottom_row, col, MPI_INT, rank+1, rank, MPI_COMM_WORLD, &receive_next_row);
}
````
Poi ogni processo inizia a calcolare il nuovo stato delle righe non vincolate (se ci sono) tramite la funzione `update_not_chained_rows()`:
```c
void update_not_chained_rows(int start_row, int end_row, int row, int col, int *process_matrix, int *new_process_matrix) {
    for (int i = start_row; i < end_row; i++) {
        for (int j = 0; j < col; j++) {
            int alives = neighbors_alive(i, j, row, col, process_matrix, NULL, NULL);

            if (process_matrix[i * col + j] == 1 && (alives == 2 || alives == 3)) {
                new_process_matrix[i * col + j] = 1;
            }
            else if (process_matrix[i * col + j] == 0 && alives == 3) {
                new_process_matrix[i * col + j] = 1;
            }
            else new_process_matrix[i * col + j] = 0;
        }
    }
}
```
Successivamente, calcola il nuovo stato di quelle vincolate con la funzione `update_chained_row()`. 
```c
void update_chained_row(int chained_row, int row, int col, int *process_matrix, int *new_process_matrix, int *top_row, int *bottom_row) {
    int i = chained_row;
    for (int j = 0; j < col; j++) {
        int alives = neighbors_alive(i, j, row, col, process_matrix, top_row, bottom_row);

        if (process_matrix[i * col + j] == 1 && (alives == 2 || alives == 3)) {
            new_process_matrix[i * col + j] = 1;
        }
        else if (process_matrix[i * col + j] == 0 && alives == 3) {
            new_process_matrix[i * col + j] = 1;
        }
        else new_process_matrix[i * col + j] = 0;
    }
}
```
In entrambi i casi viene utilizzata la funzione `neighbords_alive()` per calcolare il numero di vicini vivi per ogni cella. Tale funzione considera tutti i prossibili casi:
1. **riga non vincolata**;
2. **riga vincolata superiormente**, ovvero che richiede la `bottom_row` del processo precedente;
3. **riga vincolata inferiormente**, ovvero che richiede la `top_row` del processo successivo;
4. **riga doppiamente vincolata**, ovvero che richiede sia la `bottom_row` che la `top_row`.
```c
int neighbors_alive(int i, int j, int row, int col, int *process_matrix, int *top_row, int *bottom_row) {
    int top = 0;
    int tl_corner = 0;
    int tr_corner = 0;
    if (i > 0) {
        top = process_matrix[(i-1) * col + j];        
        if (j > 0) {
            tl_corner = process_matrix[(i-1) * col + (j-1)];
        }
        if (j < col-1) {
            tr_corner = process_matrix[(i-1) * col + (j+1)];
        }
    } 
    else if(top_row != NULL) {
        top = top_row[j];
        if (j > 0) {
            tl_corner = top_row[j-1];
        }
        if (j < col-1) {
            tr_corner = top_row[j+1];
        }
    }

    int left = (j > 0) ? process_matrix[i * col + (j-1)] : 0;
    int right = (j < col-1) ? process_matrix[i * col + (j+1)] : 0;

    int bottom = 0;
    int bl_corner = 0;
    int br_corner = 0;
    if (i < row-1) {
        bottom = process_matrix[(i+1) * col + j];
        if (j > 0) {
            bl_corner = process_matrix[(i+1) * col + (j-1)];
        }
        if (j < col-1) {
            br_corner = process_matrix[(i+1) * col + (j+1)];
        }
    }
    else if(bottom_row != NULL) {
        bottom = bottom_row[j];
        if (j > 0) {
            bl_corner = bottom_row[j-1];
        }
        if (j < col-1) {
            br_corner = bottom_row[j+1];
        }
    }

    return top + left + right + bottom + tl_corner + tr_corner + bl_corner + br_corner;
}
```
Lo stato di ogni cella viene letto dalla matrice di lettura (`process_matrix`), invece, il nuovo stato viene scritto nella matrice di scrittura (`new_process_matrix`). Per ottimizzare la memoria utilizzata, al termine di ogni generazione viene effettuato uno swap di queste matrici con la funzione `swap()`:
```c
void swap(int **current_matrix, int **new_matrix) {
    int *temp = *current_matrix;
    *current_matrix = *new_matrix;
    *new_matrix = temp;
}
```
Al termine di tutte le generazioni, il proccesso master mediante una `MPI_GATHERV()` ottiene tutte le `process_matrix` e le aggrega all'interno di `matrix`. All'interno di `matrix` ci sarà lo stato finale al termine di tutte le generazioni.

## Correttezza
Lo stato delle diverse generazioni viene correttemente calcolato seguendo le regole del gioco. Inoltre, le modifiche dello stato di tutte le celle da una generazione alla successiva avvengono in simultaneo, perché lo stato attuale di ogni cella è letto da una matrice, viene calcolato il nuovo e scritto su un'altra matrice. Utilizzare due matrici, una in scrittura ed una in lettura, che si alternano ad ogni generazione permette di risparmiare in termini di memoria utilizzata.

## Benchmarks
L'agoritmo è stato testato su **Google Cloud Platform** su un cluster di 6 macchine **e2-standard**. Ogni macchina è dotata di 4 VCPUs, quindi per un totale di 24 VCPUs. L'algorimo è stato testato in termini di **strong scalability** e **weak scalability**. Di seguti possiamo visionare i risultati.

### Strong Scalability
L'algoritmo è stato esegutio su una matrice di 12800x12800 elementi. Lo speed up è stato calcolando dividendo il tempo di esecuzione con un processore con il tempo di esecuzione con **P** processori.
| VCPUs | Tempo in s | Speed up |
|-------|------------|----------|
|   1   |            |     -    |
|   2   |            |          |
|   3   |            |          |
|   4   |            |          |
|   5   |            |          |
|   6   |            |          |
|   7   |            |          |
|   8   |            |          |
|   9   |            |          |
|   10  |            |          |
|   11  |            |          |
|   12  |            |          |
|   13  |            |          |
|   14  |            |          |
|   15  |            |          |
|   16  |            |          |
|   17  |            |          |
|   18  |            |          |
|   19  |            |          |
|   20  |            |          |
|   21  |            |          |
|   22  |            |          |
|   23  |            |          |
|   24  |            |          |

![strong_scalability](results/strong_scalability.png)

### Weak Scalability
L'algoritmo è stato eseguito su una matrixe di 1000**P**x24000, dove **P** è il numero di processori.
| VCPUs | Tempo in s |
|-------|------------|
|   1   |            |
|   2   |            |
|   3   |            |
|   4   |            |
|   5   |            |
|   6   |            |
|   7   |            |
|   8   |            |
|   9   |            |
|   10  |            |
|   11  |            |
|   12  |            |
|   13  |            |
|   14  |            |
|   15  |            |
|   16  |            |
|   17  |            |
|   18  |            |
|   19  |            |
|   20  |            |
|   21  |            |
|   22  |            |
|   23  |            |
|   24  |            |

![weak_scalability](results/weak_scalability.png)

## Analisi dei Risultati
``
