import React from 'react';

const Banner = ({ parentStyles, chlidStyles, name }) => (
  <div
    className={`relative w-full flex items-center z-0 overflow-hidden nft-gradient ${parentStyles}`}
  >
    <p
      className={`font-bold text-5xl text-white font-poppins leading-70 ${chlidStyles}`}
    >
      {name}
    </p>
    <div className="absolute w-48 h-48 sm:w-32 sm:h-32 rounded-full -top-9 -left-16 -z-5 white-bg" />
    <div className="absolute w-72 h-72 sm:w-56 sm:h-56 rounded-full -bottom-24 -right-14 -z-5 white-bg" />
  </div>
);

export default Banner;
