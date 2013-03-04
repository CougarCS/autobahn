-- SQLite schema

PRAGMA encoding = "UTF-8";
PRAGMA foreign_keys = ON;

CREATE TABLE if not exists profile (
	userid INTEGER PRIMARY KEY,
	name TEXT NOT NULL,
	fullname TEXT NOT NULL,
	description TEXT NOT NULL,
	jointime INTEGER NOT NULL,
	lastloggedin INTEGER NOT NULL
);

CREATE TABLE if not exists userlogin (
	userid INTEGER PRIMARY KEY,
	githubuser TEXT NOT NULL,

	FOREIGN KEY(userid) REFERENCES profile(userid)
);

CREATE TABLE if not exists useravatar (
	userid INTEGER PRIMARY KEY,
	avatarurl TEXT NOT NULL,

	FOREIGN KEY(userid) REFERENCES profile(userid)
);

CREATE TABLE if not exists project (
	projectid INTEGER PRIMARY KEY,
	projectuid TEXT NOT NULL UNIQUE,
	title TEXT NOT NULL,
	description TEXT NOT NULL,
	githubrepo TEXT NOT NULL,
	creator INTEGER NOT NULL,
	createtime INTEGER NOT NULL,

	FOREIGN KEY(creator) REFERENCES profile(userid)
);

CREATE TABLE if not exists userprojectinterest (
	userid INTEGER NOT NULL,
	projectid INTEGER NOT NULL,

	PRIMARY KEY (userid, projectid),

	FOREIGN KEY(userid) REFERENCES profile(userid),
	FOREIGN KEY(projectid) REFERENCES project(projectid)
);

CREATE TABLE if not exists skill (
	skillid INTEGER PRIMARY KEY,
	name TEXT NOT NULL,
	description TEXT NOT NULL
);

CREATE TABLE if not exists userskill (
	userid INTEGER NOT NULL,
	skillid INTEGER NOT NULL,
	skillstate INTEGER NOT NULL,

	PRIMARY KEY (userid, skillid),

	FOREIGN KEY(userid) REFERENCES profile(userid),
	FOREIGN KEY(skillid) REFERENCES skill(skillid)
);

CREATE TABLE if not exists projectskill (
	projectid INTEGER NOT NULL,
	skillid INTEGER NOT NULL,

	PRIMARY KEY (projectid, skillid),

	FOREIGN KEY(projectid) REFERENCES project(projectid),
	FOREIGN KEY(skillid) REFERENCES skill(skillid)
);
