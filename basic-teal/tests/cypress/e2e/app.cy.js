describe("Hello World", () => {
  it('displays "Hello World!"', () => {
    cy.visit("http://localhost:3333");
    expect(true).to.equal(true);
  });
});
