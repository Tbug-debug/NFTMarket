export const shortenAddress = (address) =>
  // eslint-disable-next-line implicit-arrow-linebreak
  `${address.slice(0, 5)}...${address.slice(address.length - 4)}`;
