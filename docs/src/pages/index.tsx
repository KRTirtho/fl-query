import React from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';
import { FiGithub } from "react-icons/fi"

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className='flex flex-col space-y-5 h-[65vh] md:p-20' style={{ backgroundImage: "url('img/logo.svg')", backgroundSize: "60% auto", backgroundRepeat: "no-repeat", backgroundPosition: "125%" }}>
      <h1 className="text-4xl flex items-center">
        <img src="img/logo.svg" className='mt-2' width="40" alt="" />
        {siteConfig.title}
      </h1>
      <p className="text-2xl max-w-[40%]">{siteConfig.tagline}</p>
      <div className='space-x-5'>
        <Link
          className="button button--primary button--lg"
          to="/docs/intro">
          Get Started
        </Link>
        <Link
          className="button button--secondary button--lg"
          href='https://github.com/KRTirtho/fl-query'
        >
          <FiGithub className='mr-1' />
          Github
        </Link>
      </div>
    </header>
  );
}

export default function Home(): JSX.Element {
  const { siteConfig } = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title} - Flutter async data management couldn't anymore easier`}
      description="Flutter Asynchronous data caching, invalidation, refetching library. React-Query for Flutter. swr for Flutter">
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
