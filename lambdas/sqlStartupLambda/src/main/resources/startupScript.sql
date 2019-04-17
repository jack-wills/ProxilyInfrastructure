DROP DATABASE IF EXISTS Proxily;
DROP USER IF EXISTS 'backend'@'%';
DROP USER IF EXISTS 'backend_iam'@'%';
CREATE DATABASE Proxily;
USE Proxily;

CREATE USER backend_iam IDENTIFIED WITH AWSAuthenticationPlugin AS 'RDS';
GRANT ALL PRIVILEGES ON Proxily.* TO 'backend_iam'@'%';

CREATE TABLE users (
    UserID int NOT NULL AUTO_INCREMENT,
    Email varchar(255) NOT NULL,
    FirstName varchar(255) NOT NULL,
    LastName varchar(255) NOT NULL,
    ProfilePicture varchar(255) NOT NULL,
    HashedPassword varchar(255),
    Salt varchar(255),
    PRIMARY KEY (UserID)
);

INSERT INTO `users` VALUES
(1, 'jackw53519@gmail.co.uk','Jack','Williams', 'https://jackwill.me/images/mountains.jpg', 'E970B2F9D4D2DC420F39E5B230B5494965DBE44F','E5D6981A2D54F19E');

CREATE TABLE posts (
    PostID int NOT NULL AUTO_INCREMENT,
    Media text NOT NULL,
    UserID int NOT NULL,
    Votes int DEFAULT 0,
    Latitude float NOT NULL,
    Longitude float NOT NULL,
    Timestamp timestamp NOT NULL,
    FileUploaded bool NOT NULL,
    PRIMARY KEY (PostID),
    FOREIGN KEY (UserID) REFERENCES users(UserID) ON DELETE CASCADE
);

CREATE TABLE users_votes (
    PostID int NOT NULL,
    UserID int NOT NULL,
    Vote bool,
    PRIMARY KEY (PostID,UserID),
    FOREIGN KEY (PostID) REFERENCES posts(PostID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES users(UserID) ON DELETE CASCADE
);

CREATE TABLE comments (
    CommentID int NOT NULL AUTO_INCREMENT,
    Content varchar(2047) NOT NULL,
    UserID int NOT NULL,
    Votes int DEFAULT 0,
    PostID int NOT NULL,
    Timestamp DATETIME NOT NULL,
    PRIMARY KEY (CommentID),
    FOREIGN KEY (PostID) REFERENCES posts(PostID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES users(UserID) ON DELETE CASCADE
);

CREATE TABLE comments_votes (
    CommentID int NOT NULL,
    UserID int NOT NULL,
    Vote bool,
    PRIMARY KEY (CommentID,UserID),
    FOREIGN KEY (CommentID) REFERENCES comments(CommentID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES users(UserID) ON DELETE CASCADE
);

CREATE TABLE saved_locations (
    SavedLocationID int NOT NULL AUTO_INCREMENT,
    UserID int NOT NULL,
    Name varchar(30) NOT NULL,
    Latitude float NOT NULL,
    Longitude float NOT NULL,
    PRIMARY KEY (SavedLocationID),
    FOREIGN KEY (UserID) REFERENCES users(UserID) ON DELETE CASCADE
);

CREATE TABLE reported_posts (
    ReportID int NOT NULL AUTO_INCREMENT,
    UserID int NOT NULL,
    PostID int NOT NULL,
    PRIMARY KEY (ReportID),
    FOREIGN KEY (PostID) REFERENCES posts(PostID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES users(UserID) ON DELETE CASCADE
);

CREATE TABLE oauths (
    UserID int NOT NULL,
    ServiceUserID bigint NOT NULL,
    Provider varchar(30) NOT NULL,
    PRIMARY KEY (UserID),
    FOREIGN KEY (UserID) REFERENCES users(UserID) ON DELETE CASCADE
);

