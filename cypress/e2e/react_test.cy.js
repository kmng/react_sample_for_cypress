/// <reference types="Cypress" />


describe('template spec', () => {
  it('passes', () => {
    cy.visit('http://stefantopia-9-25-2023.s3-website-us-west-2.amazonaws.com/')
  })
});


describe('tasks page', () => {
  it('should render the main image', () => {
    cy.visit('http://stefantopia-9-25-2023.s3-website-us-west-2.amazonaws.com/');
    cy.get('.main-header').find('img');
    // cy.get('.main-header img'); // => also works!
  });

  it('should display the page title', () => {
    cy.visit('http://stefantopia-9-25-2023.s3-website-us-west-2.amazonaws.com/');
    cy.get('h1').should('have.length', 1);
    cy.get('h1').contains('React Tasks version 4');
    // cy.contains('My Cypress Course Tasks');
  });
});

describe('tasks management', () => {
  it('should open and close the new task modal', () => {
    cy.visit('http://stefantopia-9-25-2023.s3-website-us-west-2.amazonaws.com/');
    cy.contains('Add Task').click();
    cy.get('.backdrop').click({ force: true });
    cy.get('.backdrop').should('not.exist');
    cy.get('.modal').should('not.exist');

    cy.contains('Add Task').click();
    cy.contains('Cancel').click();
    cy.get('.backdrop').should('not.exist');
    cy.get('.modal').should('not.exist');
  });

  it('should create a new task', () => {
    cy.visit('http://stefantopia-9-25-2023.s3-website-us-west-2.amazonaws.com/');
    cy.contains('Add Task').click();
    cy.get('#title').type('New Task');
    cy.get('#summary').type('Some description');
    cy.get('.modal').contains('Add Task').click();
    cy.get('.backdrop').should('not.exist');
    cy.get('.modal').should('not.exist');
    cy.get('.task').should('have.length', 1);
    cy.get('.task h2').contains('New Task');
    cy.get('.task p').contains('Some description');
  });

  it('should validate user input', () => {
    cy.visit('http://stefantopia-9-25-2023.s3-website-us-west-2.amazonaws.com/');
    cy.contains('Add Task').click();
    cy.get('.modal').contains('Add Task').click();
    cy.contains('Please provide values');
  });

  it('should filter tasks', () => {
    cy.visit('http://stefantopia-9-25-2023.s3-website-us-west-2.amazonaws.com/');
    cy.contains('Add Task').click();
    cy.get('#title').type('New Task');
    cy.get('#summary').type('Some description');
    cy.get('#category').select('urgent');
    cy.get('.modal').contains('Add Task').click();
    cy.get('.task').should('have.length', 1);
    cy.get('#filter').select('moderate');
    cy.get('.task').should('have.length', 0);
    cy.get('#filter').select('urgent');
    cy.get('.task').should('have.length', 1);
    cy.get('#filter').select('all');
    cy.get('.task').should('have.length', 1);
  });

  it('should add multiple tasks', () => {
    cy.visit('http://stefantopia-9-25-2023.s3-website-us-west-2.amazonaws.com/');
    cy.contains('Add Task').click();
    cy.get('#title').type('Task 1');
    cy.get('#summary').type('First task');
    cy.get('.modal').contains('Add Task').click();
    cy.get('.task').should('have.length', 1);

    cy.contains('Add Task').click();
    cy.get('#title').type('Task 2');
    cy.get('#summary').type('Second task');
    cy.get('.modal').contains('Add Task').click();
    cy.get('.task').should('have.length', 2);
    cy.get('.task').eq(0).contains('First task'); // first()
    cy.get('.task').eq(1).contains('Second task'); // last()
  });
});