# Script per ricaricare la configurazione delle celle dect Snom M900

Con 3cx per aggiornare la configurazione delle celle è necessario riavviare la cella dect configurata per il provisioning.
Questo script permette di farlo in modo automatico.

N.B. linux only :)

## Scaricare ed eseguire lo script

Scaricare lo script e cambiare i permessi in modo che possa essere eseguito

```bash
chmod +x m900.sh
```

eseguire lo script con `./m900.sh` compare un menu con due scelte:

- creare una nuova cella
- eseguire il provisioning di una cella già creata con lo script

## Utilizzo

Nota bene è necessario che sipsak sia installato per fare funzionare lo script.

Per ogni cella aggiunta verrà creato un file con estensione `m900` che contiene i dati necessari al provisioning della cella che sono quelli richiesti in fase di aggiunta. Se i dati fossero sbagliati o sono stati cambiati, cancellare il file con estensione `m900` e rifare la procedura di creazione di una nuova cella.

Una volta create le celle di provisioning (una o più) verranno elencate con l'opzione 2, basta selezionare quella da aggiornare e il refresh del provisioning avviene automaticamente.

Lo script funziona anche in remoto se raggiungete la cella e il pbx.

Testato con le celle dect Snom M900 ma dovrebbe funzionare anche con le M400 e M700.