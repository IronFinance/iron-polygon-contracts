module.exports = {
  singleQuote: true,
  bracketSpacing: false,
  printWidth: 100,
  overrides: [
    {
      files: '*.sol',
      options: {
        tabWidth: 4,
        printWidth: 120,
        singleQuote: false,
        explicitTypes: 'always',
      },
    },
  ],
};
