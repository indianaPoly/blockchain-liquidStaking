# chmod +x deploy_sepolia.bash => 실행 권한 부여
# ./deploy_sepolia.bash => 실행

SCRIPT_DIR = "scripts/deploy/sepolia"
FLIES = ("mockToken.ts" "staking.ts" "stbtc.ts")
HARDHAT_CMD = "npx hardhat run"
NETWORK = "sepolia"

for FILE in "${FILES[@]}"; do
  echo "Deploying $FILE to $NETWORK network..."
  $HARDHAT_CMD $SCRIPT_DIR/$FILE --network $NETWORK
  if [ $? -eq 0]; then
    ehco "$FILE deployed successfully"
  else
    ehco "ERROR deploying $FILE. Exiting script."
    exit 1
  fi
done

echo "All scripts executed successfully."