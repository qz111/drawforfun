import 'animal_template.dart';

/// Static registry of all 25 built-in animal templates.
/// Order determines display order in the Template Screen grid.
class AnimalTemplates {
  AnimalTemplates._();

  static const List<AnimalTemplate> all = [
    AnimalTemplate(id: 'cat',        name: 'Cat',        emoji: '🐱', assetPath: 'assets/line_art/cat.svg'),
    AnimalTemplate(id: 'dog',        name: 'Dog',        emoji: '🐶', assetPath: 'assets/line_art/dog.svg'),
    AnimalTemplate(id: 'fox',        name: 'Fox',        emoji: '🦊', assetPath: 'assets/line_art/fox.svg'),
    AnimalTemplate(id: 'panda',      name: 'Panda',      emoji: '🐼', assetPath: 'assets/line_art/panda.svg'),
    AnimalTemplate(id: 'rabbit',     name: 'Rabbit',     emoji: '🐰', assetPath: 'assets/line_art/rabbit.svg'),
    AnimalTemplate(id: 'monkey',     name: 'Monkey',     emoji: '🐵', assetPath: 'assets/line_art/monkey.svg'),
    AnimalTemplate(id: 'elephant',   name: 'Elephant',   emoji: '🐘', assetPath: 'assets/line_art/elephant.svg'),
    AnimalTemplate(id: 'lion',       name: 'Lion',       emoji: '🦁', assetPath: 'assets/line_art/lion.svg'),
    AnimalTemplate(id: 'giraffe',    name: 'Giraffe',    emoji: '🦒', assetPath: 'assets/line_art/giraffe.svg'),
    AnimalTemplate(id: 'bear',       name: 'Bear',       emoji: '🐻', assetPath: 'assets/line_art/bear.svg'),
    AnimalTemplate(id: 'horse',      name: 'Horse',      emoji: '🐴', assetPath: 'assets/line_art/horse.svg'),
    AnimalTemplate(id: 'cow',        name: 'Cow',        emoji: '🐮', assetPath: 'assets/line_art/cow.svg'),
    AnimalTemplate(id: 'pig',        name: 'Pig',        emoji: '🐷', assetPath: 'assets/line_art/pig.svg'),
    AnimalTemplate(id: 'sheep',      name: 'Sheep',      emoji: '🐑', assetPath: 'assets/line_art/sheep.svg'),
    AnimalTemplate(id: 'chicken',    name: 'Chicken',    emoji: '🐔', assetPath: 'assets/line_art/chicken.svg'),
    AnimalTemplate(id: 'duck',       name: 'Duck',       emoji: '🦆', assetPath: 'assets/line_art/duck.svg'),
    AnimalTemplate(id: 'frog',       name: 'Frog',       emoji: '🐸', assetPath: 'assets/line_art/frog.svg'),
    AnimalTemplate(id: 'turtle',     name: 'Turtle',     emoji: '🐢', assetPath: 'assets/line_art/turtle.svg'),
    AnimalTemplate(id: 'fish',       name: 'Fish',       emoji: '🐟', assetPath: 'assets/line_art/fish.svg'),
    AnimalTemplate(id: 'whale',      name: 'Whale',      emoji: '🐳', assetPath: 'assets/line_art/whale.svg'),
    AnimalTemplate(id: 'owl',        name: 'Owl',        emoji: '🦉', assetPath: 'assets/line_art/owl.svg'),
    AnimalTemplate(id: 'penguin',    name: 'Penguin',    emoji: '🐧', assetPath: 'assets/line_art/penguin.svg'),
    AnimalTemplate(id: 'butterfly',  name: 'Butterfly',  emoji: '🦋', assetPath: 'assets/line_art/butterfly.svg'),
    AnimalTemplate(id: 'crocodile',  name: 'Crocodile',  emoji: '🐊', assetPath: 'assets/line_art/crocodile.svg'),
    AnimalTemplate(id: 'bird',       name: 'Bird',       emoji: '🐦', assetPath: 'assets/line_art/bird.svg'),
  ];
}
