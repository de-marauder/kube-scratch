# Bird Application

This is the bird Application! It gives us birds!!!

The app is written in Golang and contains 2 APIs:
- the bird API
- the birdImage API

When you run the application (figure it out), you will see the relationship between those 2 APIs.

# installation & how to run it

- In each of the API directories, there's a makefile. Run `make` in each directory to install dependencies and build the go binary and run the output binaries
  ```
  cd bird
  make
  ./getBird
  # Application server is started on port 4201

  ##################################

  cd birdImage
  make
  ./getBirdImage
  # Application server is started on port 4200
  ```
- You can proceed to test with any http client of your choice like `curl` or `postman`
- Going through the code shows that the bird API depends on the birdImage API. To work with this, the `localhost` reference has been swapped with an environment variable called `BIRD_API_HOST`. This will allow us to supply a custom value when building or running the application container.


# Challenge

How to:
- [x] fork the repository
- [ ] work on the challenges
- [ ] share your repository link with the recruitment team

Here are the challenges:
- [x] Install and run the app
- [x] Dockerize it (create dockerfile for each API)
- [ ] Create an infra on AWS (VPC, SG, instances) using IaC
- [ ] Install a small version of kubernetes on the instances (no EKS)
- [ ] Build the manifests to run the 2 APIs on k8s 
- [ ] Bonus points: observability, helm, scaling

Rules:
- Use security / container / k8s / cloud best practices
- Change in the source code is possible

Evaluation criterias:
- best practices
- code organization
- clarity & readability