#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -q"
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

printf '%s\n' "Enter your username:"
if ! IFS= read -r USERNAME; then
  exit 1
fi
USERNAME_SQL=${USERNAME//\'/\'\'}

USER_DATA=$($PSQL -c "SELECT users.user_id, COUNT(games.game_id), MIN(games.number_guesses) FROM users LEFT JOIN games USING (user_id) WHERE users.username = '$USERNAME_SQL' GROUP BY users.user_id;")

if [[ -n "$USER_DATA" ]]; then
  IFS='|' read -r USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  printf 'Welcome back, %s! You have played %s games, and your best game took %s guesses.\n' "$USERNAME" "$GAMES_PLAYED" "$BEST_GAME"
else
  USER_ID=$($PSQL -c "INSERT INTO users(username) VALUES ('$USERNAME_SQL') RETURNING user_id;")
  printf 'Welcome, %s! It looks like this is your first time here.\n' "$USERNAME"
fi

printf '%s\n' 'Guess the secret number between 1 and 1000:'
if ! IFS= read -r GUESS; then
  exit 1
fi
NUMBER_OF_GUESSES=0

while true; do
  ((NUMBER_OF_GUESSES += 1))

  if [[ ! "$GUESS" =~ ^-?[0-9]+$ ]]; then
    printf '%s\n' 'That is not an integer, guess again:'
  else
    if [[ "$GUESS" == -* ]]; then
      GUESS_NUMBER=$((-10#${GUESS#-}))
    else
      GUESS_NUMBER=$((10#$GUESS))
    fi

    if (( GUESS_NUMBER == SECRET_NUMBER )); then
      break
    elif (( GUESS_NUMBER > SECRET_NUMBER )); then
      printf '%s\n' "It's lower than that, guess again:"
    else
      printf '%s\n' "It's higher than that, guess again:"
    fi
  fi

  if ! IFS= read -r GUESS; then
    exit 1
  fi
done

printf 'You guessed it in %s tries. The secret number was %s. Nice job!\n' "$NUMBER_OF_GUESSES" "$SECRET_NUMBER"
$PSQL -c "INSERT INTO games(user_id, number_guesses) VALUES ($USER_ID, $NUMBER_OF_GUESSES);" >/dev/null
