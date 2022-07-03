import React, { ReactElement } from 'react';
import clsx from 'clsx';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  Svg?: React.ComponentType<React.ComponentProps<'svg'>>;
  Png?: string;
  description: JSX.Element;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'No boilerplate & high code reusability',
    Png: 'img/no_boilerplate_code.png',
    description: (
      <>
        Fl-Query is designed to be less cluttering + reusable and lets you focus on only the logic you actually want to implement without handling hazard of cached data management
      </>
    ),
  },
  {
    title: 'Declarative & Easy to use',
    Svg: require('@site/static/img/declarative_ui_icon.svg').default,
    description: (
      <>
        Define your logic once and distribute it thousand times. By using Fl-Query you never have to write the same logic twice. It has an easy to understand API that you can learn in only 2-4 hours
      </>
    ),
  },
  {
    title: 'Optimistic data with smart refetching',
    Svg: require('@site/static/img/optimistic_data.svg').default,
    description: (
      <>
        The days of Loading Screen is over. Fetch and update your data transparently without disturbing the user with a Loading Indicator. Update your Data even before a data updates on the server and after finally getting the actual data, replace the predicted data with the real one
      </>
    ),
  },
];

function Feature({ title, Svg, description, Png }: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        {Svg && <Svg className={styles.featureSvg} role="img" />}
        {Png && <img src={Png} />}
      </div>
      <div className="text--center padding-horiz--md">
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): JSX.Element {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
