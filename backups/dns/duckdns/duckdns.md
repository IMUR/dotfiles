# Duck DNS - Linux Cron Setup (Domain: crtrcooperator)

Duck DNS provides free dynamic DNS hosted on AWS.

## Preliminary Steps

- Confirm **cron** is running:
  ```
  ps -ef | grep cr[o]n
  ```
  If nothing returns, install cron for your distro.

- Confirm **curl** is installed:
  ```
  curl
  ```
  If 'command not found', install curl for your distro.

## Setup Directory and Script

1. Create a directory and navigate into it:
    ```
    mkdir duckdns
    cd duckdns
    ```

2. Create main script with vi:
    ```
    vi duck.sh
    ```
    - Press `i` to insert, `ESC` then `u` to undo.
    - Paste the following script (replace the token and domain if different):

    ```
    echo url="https://www.duckdns.org/update?domains=crtrcooperator&token=dd3810d4-6ea3-497b-832f-ec0beaf679b3&ip=" | curl -k -o ~/duckdns/duck.log -K -
    ```

    - Save and exit in vi: `ESC` then `:wq!` then `ENTER`

3. Make the script executable:
    ```
    chmod 700 duck.sh
    ```

## Setup Cron

Edit your crontab:
```
crontab -e
```
Paste at the bottom:
```
*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1
```
Save the file (in nano: `CTRL+o`, then `CTRL+x`).

## Test the Script

Run:
```
./duck.sh
```
- Should simply return to prompt.

Check latest log/result:
```
cat duck.log
```
- **OK** means success, **KO** means error (check Token and Domain).
