var settings = {
  bot: {
    server: '',
    port: 6667,
    channels: ['#channel'],
    botName: '',
    userName: '',
    realName: '',
    // Omit this if you don't need SSL
    secure: {passphrase: ''},
    password: '',
    certExpired: true,
    selfSigned: true
    // Debugging things
    //debug: true,
    //showErrors: true,
  },

  server:  {
    port: 3000,
    db: 'test',
    host: 'localhost'
  }
}

if (module && module.exports)
  module.exports = settings;
